# Understanding XKB Keymaps

key = keycode

## Key

Can be special cases (ESC, TAB/BKSP) or mapping code 

### Mapping Codes

Made up of [<Section> <Row> <Number>]

#### Sections

 - A (Alphanumeric)
 - F (Function)
 - I (International?)

#### Rows

 - Rows up from bottom

#### Number

 - Columns across from left-hand side


## Reading xkb_keymap

### Format (xkb_keycodes)

```
xkb_keycodes "<name>" {
    minimum = <min-val>;
    maximum = <max-val>;

    // for min-val -> max-val
    <KEY> = <keycode>;
    indicator <num> = "key name";
    alias <KEY> = <KEY>;


};
```

### Format (xkb_types) 

```
xkb_types "<name>" {
    virtual_modifiers Mod1,Mod2,...,Modn;

    type "<TYPENAME>" {
        modifiers= none|modname_1(+modname_2+...+modname_n);
        (map[modname_1]= k;)
        (preserve[modname_1]= "<modname>";)
        (map[modname_2]= k;)
        (preserve[modname_2]= "<modname>";)
        (...)
        (map[modname_n]= k;)
        (preserve[modname_n]= "<modname>";)
        level_name[1]= "<name>";
        (level_name[2]= "<name>";)
        (...)
        (level_name[n]= "<name>";)
    };
};

```

### Format (xkb_types) 

```
xkb_compatibility "<name>" {
    virtual_modifiers Mod1,Mod2,...,Modn;

    interpret.useModMapMods= <level|AnyLevel>;
    interpret.repeat= True|False;
    interpret <Mod|Key>+<Exactly|AnyOf|AnyOfOrNone>(all|Mod1(+...+ModN)) {
        (useModMapMods=<level>;)
        (action= <Action>(<args>);) 
    };
    /* Assume unknown number of (interpret <...> {...};) declarations */

    indicator "<Indicator Name>" {
        (whichModState= <state>;)
        (modifier= Modk;)
        (groups= <value>;)/* where value is hex format int */
        (controls= <controlled>)
    };
    /* Assume unknown number of (indicator <...> {...};) declarations */

};

```

### Format (xkb_symbols)

```
xkb_symbols "<name>" {

    name[Group<n>]="<Name Of Group>";

    // for min-val -> max-val
    key <KEY> { [ <level_1 val>, .., <level_n val> ] };
    key <KEY> { type= "typename", symbols[Group<n>]= [groups]};

    modifer_map <mod> { <mod_key_1>, ..., <mod_key_n> };
};
```



