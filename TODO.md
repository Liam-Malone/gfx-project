# Wayland Input Handling

- [-] Keyboard & Mouse input events
    - [x] Basic logging of key inputs (press/release)
    - [x] Basic xkb_keymap parser
        - [x] Map Keycode to Symbol
        - [x] Map Symbol to Key
        - [x] Map Key to input.Keyboard.Key
        - [x] Return `XkbMappings` object when given keymap 
        - [x] Map xkb_keys to keys program cares about
    - [x] Track Key State
    - [ ] Track Modifiers
    - [ ] Basic logging of mouse inputs (press/release)
- [ ] 'System Event' Queue

