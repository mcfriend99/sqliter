import os
import sqlite
import razor { Razor }

import .functions

var app = Razor(1024, 640, true)
app.set_title('SQLiteR')
app.load_file(os.join_paths(os.dir_name(__root__), 'src/index.html'))

for name, function in functions() {
  app.bind(name, function)
}

app.run()
