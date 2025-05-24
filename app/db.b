import sqlite

var LocalDB

def db(path) {
  if LocalDB {
    LocalDB.close()
  }

  LocalDB = sqlite.open(path)

  var tables = LocalDB.fetch('PRAGMA table_list;')
  for table in tables {
    table.schema = LocalDB.fetch('PRAGMA table_info(${table.name});')
    table.indexes = LocalDB.fetch('PRAGMA index_list(${table.name})')
  }

  return tables
}

def query(args) {
  if !LocalDB return nil

  var query = args.first()
  if !query.ends_with(';') query += ';'
  
  var data = LocalDB.fetch(query, args[1,])
  if data {
    var fields = data.first().keys()
    return { fields, data, query }
  }

  return []
}
