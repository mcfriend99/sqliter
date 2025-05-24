import .file_open_dialog
import .db

def functions() {
  return {
    fileExists: @(args) {
      return file(args.first()).exists()
    },
    openDB: @(args) {
      var path = file_open_dialog(['db'])
      if path {
        var name = path.split('/').last().upper()
        if name.length() > 20 {
          name = name[,8] + '..' + name[name.length() - 8,]
        }

        return {
          path,
          name,
          data: db(path),
        }
      }

      return nil
    },
    openFile: @(args) {
      var path = file_open_dialog(['sql', 'txt'])
      if path {
        return {
          path,
          name: path.split('/').last(),
          content: file(path).read(),
        }
      }

      return nil
    },
    # runQuery: @(args) {
    #   return db.fetch(args.first())
    # },
    runQuery: @(args) {
      return db.query(args)
    },
  }
}
