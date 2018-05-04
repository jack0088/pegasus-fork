# Install Pegasus HTTP Server on new machine

I prefer to have all my vendor sources locally, right inside the project folder, whenever possible.
Pegasus is written in pure Lua and consists only of a few C dependencies and a couple of Lua files.
All the Lua files have been placed into this project directory, while their C interfaces remain to be installed separately through `luarocks`.

1. First create a project folder `mkdir <name>` and switch to it `cd <name>`
2. Download/Clone the Pegasus repo `git clone https://github.com/EvandroLG/pegasus.lua.git pegasus`
3. Switch to the repo folder and run the makefile to install the dependencies for Pegasus `make install_dependencies`

# TODO

Create a Makefile and change this description to just run `make` and everything should be handled automatically.