# Client Reworking

- [ ] `interfaces.zig` map of interface names to interface types, will also contain registry
- [ ] methods which take `new_id` param will use `interfaces.next_id()` for said id, and will return an object of typeof(param `interface`)
- [ ] methods which have type `destructor` will call `interfaces.remove()` with id of the object
