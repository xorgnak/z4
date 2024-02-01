
# Z4
A simple project to integrate local large language model interactions to the low-power and IoT world.

## VIRTUAL PRE-QUICKSTART
Skip this step if installing z4 on *actual* hardware running a Debian.
1. Clone this repository and run the vm script.
```
cd ~ && git clone https://github.com/xorgnak/z4 && cd z4 && ./exe/vm
```
1. Continue with the QUICKSTART instructions from inside of the VM.
1. Exit the VM when done with QUICKSTART instructions.


## QUICKSTART
1. Clone this repository and run the setup script.
```
cd ~ && git clone https://github.com/xorgnak/z4 && cd z4 && ./exe/setup
```
1. Use `./exe/server` to begin the z4 server in headless mode.
1. Use `./exe/client` to begin the z4 server in interactive mode.
1. The local z4 server is running at "http://localhost:4567"
  - Use `./exe/nginx` to setup port 80 proxy access.
  - Use `./exe/tor` to setup .onion proxy access.



