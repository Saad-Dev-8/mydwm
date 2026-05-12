/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 0;        /* border pixel of windows */
static const unsigned int gappih    = 12;        /* horiz inner gap between windows */
static const unsigned int gappiv    = 12;        /* vert inner gap between windows */
static const unsigned int gappoh    = 12;        /* horiz outer gap between windows and screen edge */
static const unsigned int gappov    = 12;        /* vert outer gap between windows and screen edge */
static       int smartgaps          = 0;        /* 1 means no outer gap when there is only one window */
static const int swallowfloating    = 0;        /* 1 means swallow floating windows by default */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor */
static const unsigned int systrayonleft = 0;    /* 0: systray in the right corner */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;
static const int showsystray        = 0;
static const int showbar            = 0;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const int focusonwheel       = 0;

/* Font */
static const char *fonts[]          = { "JetBrainsMono Nerd Font:size=10" };
static const char dmenufont[]       = "JetBrainsMono Nerd Font:size=10";

/* Nord colorscheme */
static const char col_bg[]          = "#2e3440";
static const char col_bg2[]         = "#3b4252";
static const char col_bg3[]         = "#434c5e";
static const char col_bg4[]         = "#4c566a";
static const char col_fg[]          = "#d8dee9";
static const char col_fg2[]         = "#eceff4";
static const char col_accent[]      = "#5e81ac";
static const char col_urgent[]      = "#bf616a";

static const char *colors[][3]      = {
	/*               fg          bg          border    */
	[SchemeNorm] = { col_fg,     col_bg,     col_bg3   },
	[SchemeSel]  = { col_fg2,    col_accent, col_accent },
};

/* tagging */
static const char *tags[] = { "", "", "", "", "", "", "", "", "" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class              instance  title           tags mask  isfloating  isterminal  noswallow  monitor */
	{ "Polybar",          NULL,     NULL,           0,         1,          0,           1,        -1 },
    { "St",               NULL,     NULL,           0,         0,          1,           0,        -1 },
	{ "firefox",          NULL,     NULL,           0,         0,          0,           0,        -1 },
	{ "Firefox",          NULL,     NULL,           0,         0,          0,           0,        -1 },
	{ "firefox-esr",      NULL,     NULL,           0,         0,          0,           0,        -1 },
	{ "Pcmanfm",          NULL,     NULL,           0,         0,          0,           0,        -1 },
	{ "Pavucontrol",      NULL,     NULL,           0,         1,          0,           0,        -1 },
	{ "Lxappearance",     NULL,     NULL,           0,         0,          0,           0,        -1 },
	{ "nmtui-floating",   NULL,     NULL,           0,         1,          0,           1,        -1 },
	{ "Gimp",             NULL,     NULL,           0,         1,          0,           0,        -1 },
	{ NULL,               NULL,     "Event Tester", 0,         0,          0,           1,        -1 },
};

/* IPC */
static const char *ipcsockpath = "/tmp/dwm.sock";
static IPCCommand ipccommands[] = {
  IPCCOMMAND( view,         1, {ARG_TYPE_UINT}   ),
  IPCCOMMAND( toggleview,   1, {ARG_TYPE_UINT}   ),
  IPCCOMMAND( tag,          1, {ARG_TYPE_UINT}   ),
  IPCCOMMAND( toggletag,    1, {ARG_TYPE_UINT}   ),
  IPCCOMMAND( tagmon,       1, {ARG_TYPE_SINT}   ),
  IPCCOMMAND( focusmon,     1, {ARG_TYPE_SINT}   ),
  IPCCOMMAND( focusstack,   1, {ARG_TYPE_SINT}   ),
  IPCCOMMAND( zoom,         1, {ARG_TYPE_NONE}   ),
  IPCCOMMAND( incnmaster,   1, {ARG_TYPE_SINT}   ),
  IPCCOMMAND( killclient,   1, {ARG_TYPE_NONE}   ),
  IPCCOMMAND( togglefloating, 1, {ARG_TYPE_NONE} ),
  IPCCOMMAND( setmfact,     1, {ARG_TYPE_FLOAT}  ),
  IPCCOMMAND( setlayout,    1, {ARG_TYPE_PTR}    ),
  IPCCOMMAND( quit,         1, {ARG_TYPE_UINT}   ),
};

/* layout(s) */
static const float mfact     = 0.5;
static const int nmaster     = 1;
static const int resizehints = 0;
static const int attachbelow = 1;
static const int lockfullscreen = 1;

#define FORCE_VSPLIT 1
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
    { "[\\]",     dwindle },
	{ "[]=",      tile },
	{ "[M]",      monocle },
	{ "[@]",      spiral },
	{ "H[]",      deck },
	{ "TTT",      bstack },
	{ "===",      bstackhoriz },
	{ "HHH",      grid },
	{ "---",      horizgrid },
	{ ":::",      gaplessgrid },
	{ "|M|",      centeredmaster },
	{ ">M>",      centeredfloatingmaster },
	{ "><>",      NULL },
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands  */
static char dmenumon[2] = "0";
static const char *dmenucmd[]      = { "rofi", "-show", "drun", NULL };
static const char *emojicmd[]      = { "rofi", "-modi emoji", "-show", "emoji", NULL };
static const char *keybindscmd[]   = { "/bin/sh", "-c", "$HOME/Projects/mydwm/scripts/dwm-keybinds.sh", NULL };
static const char *termcmd[]       = { "st", NULL };
static const char *browsercmd[]    = { "firefox", NULL };
static const char *filecmd[]       = { "pcmanfm", NULL };
static const char *scrcmd[]        = { "flameshot", "gui", NULL };
static const char *scrfullcmd[]    = { "flameshot", "full", NULL };
static const char *volupcmd[]      = { "pamixer", "-i", "5", NULL };
static const char *voldowncmd[]    = { "pamixer", "-d", "5", NULL };
static const char *voltogcmd[]     = { "pamixer", "-t", NULL };
static const char *brupcmd[]       = { "brightnessctl", "-d", "amdgpu_bl1", "set", "+5%", NULL };
static const char *brdowncmd[]     = { "brightnessctl", "-d", "amdgpu_bl1", "set", "5%-", NULL };
static const char *wallcmd[]       = { "/bin/sh", "-c", "feh --randomize --bg-fill ~/Pictures/Wallpapers/*", NULL };
static const char *powercmd[]      = { "/bin/sh", "-c", "~/.config/rofi/powermenu.sh", NULL };

static const char scratchpadname[] = "scratchpad";
static const char *scratchpadcmd[] = { "st", "-t", scratchpadname, "-g", "120x34", NULL };

#include "movestack.c"

static const Key keys[] = {
	/* modifier                     key                 function        argument */

	/* applications */
	{ MODKEY,                       XK_x,               spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_r,               spawn,          {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_m,               spawn,          {.v = emojicmd } },
	{ MODKEY,                       XK_slash,           spawn,          {.v = keybindscmd } },
	{ MODKEY,                       XK_b,               spawn,          {.v = browsercmd } },
	{ MODKEY,                       XK_e,               spawn,          {.v = filecmd } },
	{ MODKEY,                       XK_p,               spawn,          {.v = scrcmd } },
	{ MODKEY|ShiftMask,             XK_p,               spawn,          {.v = scrfullcmd } },
	{ MODKEY|ShiftMask,             XK_w,               spawn,          {.v = wallcmd } },
	{ MODKEY|ControlMask,           XK_q,               spawn,          {.v = powercmd } },
	{ MODKEY,                       XK_grave,           togglescratch,  {.v = scratchpadcmd } },

	/* volume */
	{ 0,                XF86XK_AudioRaiseVolume,         spawn,          {.v = volupcmd } },
	{ 0,                XF86XK_AudioLowerVolume,         spawn,          {.v = voldowncmd } },
	{ 0,                XF86XK_AudioMute,                spawn,          {.v = voltogcmd } },

	/* brightness */
	{ 0,                XF86XK_MonBrightnessUp,          spawn,          {.v = brupcmd } },
	{ 0,                XF86XK_MonBrightnessDown,        spawn,          {.v = brdowncmd } },

	/* window management */
	{ MODKEY,                       XK_q,               killclient,     {0} },
	{ MODKEY,                       XK_j,               focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,               focusstack,     {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_j,               movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,               movestack,      {.i = -1 } },
	{ MODKEY,                       XK_Left,            focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_Right,           focusstack,     {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Left,            movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Right,           movestack,      {.i = +1 } },
	{ MODKEY,                       XK_h,               setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,               setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_i,               incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,               incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_Return,          zoom,           {0} },
	{ MODKEY,                       XK_Tab,             view,           {0} },
	{ MODKEY|ShiftMask,             XK_space,           togglefloating, {0} },
	{ MODKEY,                       XK_f,               togglefullscr,  {0} },

	/* exit */
	{ MODKEY|ShiftMask,             XK_e,               quit,           {0} },

	/* layouts */
	{ MODKEY,                       XK_t,               setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_m,               setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_space,           setlayout,      {0} },
	{ MODKEY|ControlMask,           XK_comma,           cyclelayout,    {.i = -1 } },
	{ MODKEY|ControlMask,           XK_period,          cyclelayout,    {.i = +1 } },

	/* gaps */
	{ MODKEY|Mod4Mask,              XK_u,               incrgaps,       {.i = +1 } },
	{ MODKEY|Mod4Mask|ShiftMask,    XK_u,               incrgaps,       {.i = -1 } },
	{ MODKEY|Mod4Mask,              XK_0,               togglegaps,     {0} },
	{ MODKEY|Mod4Mask|ShiftMask,    XK_0,               defaultgaps,    {0} },

	/* monitors */
	{ MODKEY,                       XK_comma,           focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period,          focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,           tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,          tagmon,         {.i = +1 } },

	/* tags */
	TAGKEYS(                        XK_1,                               0)
	TAGKEYS(                        XK_2,                               1)
	TAGKEYS(                        XK_3,                               2)
	TAGKEYS(                        XK_4,                               3)
	TAGKEYS(                        XK_5,                               4)
	TAGKEYS(                        XK_6,                               5)
	TAGKEYS(                        XK_7,                               6)
	TAGKEYS(                        XK_8,                               7)
	TAGKEYS(                        XK_9,                               8)
};

/* button definitions */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
};
