# native Linux guest mode {#guest}

* runs as a generic user-level application
* lacks support for some features such as @ref rtos
* mostly for debugging purposes and general application components development

```
$ cd socks
$ cargo run lib/init.f lib/guest.f
```
