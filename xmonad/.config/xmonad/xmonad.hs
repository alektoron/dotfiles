import XMonad


import System.IO (hPutStrLn)
import XMonad.Layout.Fullscreen (fullscreenEventHook, fullscreenManageHook, fullscreenSupport, fullscreenFull)
import XMonad.Actions.CopyWindow (kill1, copyToAll, killAllOtherCopies)
import XMonad.Actions.CycleWS (nextScreen, prevScreen)
import XMonad.Actions.MouseResize
import XMonad.Hooks.ManageDocks
    ( avoidStruts, docks, manageDocks, ToggleStruts(..) )
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, doCenterFloat, isDialog)
import XMonad.Hooks.SetWMName
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Layout.MultiToggle (Toggle(Toggle), mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import XMonad.Layout.Spacing
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.ResizableTile
import XMonad.Layout.Simplest
import XMonad.Layout.Accordion (Accordion (Accordion))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.LayoutModifier
import XMonad.Layout.Renamed
import XMonad.Layout.NoBorders
import XMonad.Layout.Tabbed
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.WindowNavigation
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import XMonad.Layout.SubLayouts
import XMonad.Util.SpawnOnce (spawnOnce)
import XMonad.Util.EZConfig (checkKeymap)
import XMonad.Util.Run (spawnPipe)

import Data.Maybe (fromJust)
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import Graphics.X11.ExtraTypes.XF86


myStartupHook :: X ()
myStartupHook = do
  spawnOnce "/usr/lib/xfce4/notifyd/xfce4-notifyd"
  spawn "$HOME/.config/xmonad/scripts/autorun.sh"
  spawnOnce "telegram-desktop"
  spawn "~/.fehbg"
  setWMName "LG3D"

altMask = mod1Mask
myTerminal = "alacritty"
myModMask = mod4Mask
myBorderWidth = 2
myNormColor = "#000000"
myFocusColor = "#bcbcbc"
myFocusFollowsMouse = True
myBrowser = "firefox"
myFileManager = "thunar"

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

myWorkspaces = [" dev ", " cli ", " web ", " chat ", " media "]

myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..]

clickable ws = "<action=xdotool key super+"++show i++">"++ws++"</action>"
    where i = fromJust $ M.lookup ws myWorkspaceIndices

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

tall     = renamed [Replace "tall"]
           $ limitWindows 5
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ mySpacing 3
           $ ResizableTall 1 (3/100) (1/2) []
monocle  = renamed [Replace "monocle"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ Full
grid     = renamed [Replace "grid"]
           $ limitWindows 9
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ mySpacing 8
           $ mkToggle (single MIRROR)
           $ Grid (16/10)



myLayoutHook = avoidStruts
               $ mouseResize
               $ windowArrange
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
  where
    myDefaultLayout = withBorder myBorderWidth tall
                                           ||| noBorders monocle
                                           ||| grid

myManageHook = composeAll
  [
    className =? "confirm" --> doFloat
    , className =? "file_progress" --> doFloat
    , className =? "dialog" --> doFloat
    , className =? "download" --> doFloat
    , title =? "Download" --> doCenterFloat
    , resource =? "lightscreen" --> doFloat
    , className =? "error" --> doFloat
    , className =? "notification" --> doFloat
    , className =? "toolbar" --> doFloat
    , title =? "Save As..." --> doFloat
    , className =? "Arandr" --> doCenterFloat
    , resource =? "telegram-desktop" --> doShift (myWorkspaces !! 3)
    , (className =? "firefox" <&&> title =? "Picture-in-Picture") --> doFloat
    , (className =? "firefox" <&&> resource =? "Dialog") --> doFloat
    , isFullscreen --> doFullFloat
    , isDialog --> doFloat
    , resource =? "desktop_window" --> doIgnore
  ]


myKeys conf@(XConfig {XMonad.modMask = super}) = M.fromList $
  [ 
    ((shiftMask .|. controlMask, xK_a),       windows copyToAll),
    ((shiftMask .|. controlMask, xK_z),       killAllOtherCopies),
    ((super,                     xK_Return),  spawn myTerminal),
    ((super     .|. shiftMask,   xK_Return),  spawn myFileManager),
    ((super,                     xK_q),       kill1),
    ((super,                     xK_Escape),  spawn "xkill"),
    ((super     .|. shiftMask,   xK_d),       spawn "rofi -show drun -show-icons"),
    ((super,                     xK_b),       spawn myBrowser),
    ((super     .|. shiftMask,   xK_r),       spawn "xmonad --recompile && xmonad --restart"),
    ((super     .|. shiftMask,   xK_space),   setLayout $ XMonad.layoutHook conf),
    ((super,                     xK_l),       spawn "xsecurelock"),
    ((altMask,                   xK_Tab),     windows W.focusUp),
    ((altMask   .|. shiftMask,   xK_Tab),     windows W.focusDown),
    ((super     .|. shiftMask,   xK_Right),   windows W.swapDown),
    ((super     .|. shiftMask,   xK_Left),    windows W.swapUp),
    ((altMask   .|. controlMask, xK_Tab),     sendMessage NextLayout),
    ((super,                     xK_f),       sendMessage $ Toggle NBFULL),
    ((super     .|. controlMask, xK_x),       spawn "autorandr --cycle && xmonad --recompile && xmonad --restart"),
    ((super,                     xK_space),   spawn "$HOME/.config/xmonad/scripts/lang_switch.sh"),
    ((super,                     xK_v),       spawn "pwvucontrol"),
    ((super     .|. controlMask, xK_m),       spawn "xfce4-settings-manager"),
    ((shiftMask .|. controlMask, xK_j),       sendMessage Shrink),
    ((shiftMask .|. controlMask, xK_k),       sendMessage Expand)
  ] ++ [
    ((super .|. shiftMask .|. altMask, xK_Right), nextScreen),
    ((super .|. shiftMask .|. altMask, xK_Left),  prevScreen)
  ] ++ [
    ((0, xK_Print),                     spawn "lightscreen"),
    ((0, xF86XK_AudioRaiseVolume),      spawn "amixer set Master 5%+"),
    ((0, xF86XK_AudioLowerVolume),      spawn "amixer set Master 5%-"),
    ((0, xF86XK_AudioMute),             spawn "amixer set Master toggle"),
    ((0, xF86XK_MonBrightnessUp),       spawn "brightnessctl set +5%"),
    ((0, xF86XK_MonBrightnessDown),     spawn "brightnessctl set 5%-")
  ] ++ [
    ((m .|. super, k), windows $ f i)
         | (i, k) <- zip (XMonad.workspaces conf) [xK_1..]
         , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  ]

main = do
  xmproc0 <- spawnPipe "xmobar -x 0 $HOME/.config/xmobar/xmobarrc0"
  xmproc1 <- spawnPipe "xmobar -x 1 $HOME/.config/xmobar/xmobarrc1"
  xmonad $ fullscreenSupport $ docks $ ewmh def
    { manageHook = myManageHook <+> manageDocks
    , terminal = myTerminal
    , modMask = myModMask
    , borderWidth = myBorderWidth
    , normalBorderColor = myNormColor
    , focusedBorderColor = myFocusColor
    , startupHook = myStartupHook
    , workspaces = myWorkspaces
    , layoutHook = myLayoutHook
    , keys = myKeys
    , logHook = dynamicLogWithPP $ xmobarPP
        { ppOutput = \x -> hPutStrLn xmproc0 x
                        >> hPutStrLn xmproc1 x
          , ppCurrent = xmobarColor "#B48EAD" "" . wrap
              "<box type=Top width=2 mt=2 color=#B48EAD>" "</box>" . clickable
          , ppHidden = xmobarColor "#81A1C1" "" . wrap
              "<box type=Bottom width=2 mt=2 color=#81A1C1>" "</box>" . clickable
          , ppHiddenNoWindows = xmobarColor "#81A1C1" ""  . clickable
          , ppTitle = xmobarColor "#ECEFF4" "" . shorten 60
          , ppSep =  "<fc=#4C566A> <fn=1>|</fn> </fc>"
          , ppUrgent = xmobarColor "#BF616A" "" . wrap "!" "!"
          , ppExtras  = [windowCount]
          , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
        }
    }
