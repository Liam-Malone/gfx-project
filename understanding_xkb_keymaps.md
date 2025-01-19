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



