import sqlite

var db = sqlite.open('/Users/mcfriendsy/Documents/HymnalDb__1.db')
var records = db.fetch('SELECT * FROM songs')

class Hymn {
  var number = 0
  var title = nil
  var chorus = nil
  var verses = []

  Hymn(number, title, chorus, verses) {
    self.number = number
    self.title = title
    self.chorus = chorus
    self.verses = verses
  }

  save() {
    db.exec('INSERT INTO hymns (number, title) VALUES (?, ?)', [
      self.number, self.title
    ])

    var hymn_id = db.last_insert_id()

    db.exec('INSERT INTO choruses (hymn_id, chorus) VALUES (?, ?)', [hymn_id, self.chorus])
    
    for index, verse in self.verses {
      db.exec('INSERT INTO verses (hymn_id, verse_number, verse) VALUES (?, ?, ?)', [
        hymn_id, index + 1, verse
      ])
    }
  }
}

# empty recors
db.exec('DELETE FROM hymns')
db.exec('DELETE FROM choruses')
db.exec('DELETE FROM verses')

# reset sequences
db.exec('DELETE FROM sqlite_sequence where name=?', ['hymns'])
db.exec('DELETE FROM sqlite_sequence where name=?', ['choruses'])
db.exec('DELETE FROM sqlite_sequence where name=?', ['verses'])

for record in records {
  # separate chorus first
  var verses = [], chorus
  var lines = record.Hymn.split('\n')

  var start_line = 0, in_chorus = false
  iter var i = 0; i < lines.length(); i++ {
    var line = lines[i].trim()

    if line.match('/^verse\s*\d$/i') {
      in_chorus = false
      start_line = i + 1
    } else if line.lower() == 'chorus' {
      in_chorus = true
      start_line = i + 1
    } else {
      if line == '' {
        if in_chorus {
          chorus = '\n'.join(lines[start_line,i])
          in_chorus = false
        } else {
          verses.append('\n'.join(lines[start_line,i]))
        }
      }
    }
  }
  
  # the separate the verses
  Hymn(record.Number, record.Title, chorus, verses).save()
}
