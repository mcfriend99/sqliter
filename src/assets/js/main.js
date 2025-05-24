document.addEventListener('DOMContentLoaded', () => {
  let databse = null;

  // --- DATAGRID ---

  // agGrid theme
  const agTheme = agGrid.themeQuartz
    .withPart(agGrid.iconSetQuartzLight)
    .withParams({
      accentColor: "#2B93EE",
      borderColor: "#F1F1F1",
      borderRadius: 4,
      browserColorScheme: "light",
      fontFamily: [
        "-apple-system",
        "BlinkMacSystemFont",
        "Segoe UI",
        "Roboto",
        "Oxygen-Sans",
        "Ubuntu",
        "Cantarell",
        "Helvetica Neue",
        "sans-serif"
      ],
      fontSize: 13,
      foregroundColor: "#333333",
      headerBackgroundColor: "#FBFBFB",
      headerFontSize: 14,
      headerFontWeight: 600,
      spacing: 5,
      wrapperBorderRadius: 4
    });

  const gridOptions = {
    theme: agTheme,
    autoSizeStrategy: {
      type: 'fitCellContents'
    },
    rowSelection: {
      mode: 'singleRow',
      checkboxes: false,
      enableClickSelection: true,
    },
  }

  /**
   * @type {[string: CodeMirror.Editor]}
   */
  const editors = {};
  const tabLayout = [];
  let tabCount = 0;

  // --- TABS ---
  const tabTemplate = document.getElementById('tab-template')
  var tabs = new Tabby('[data-tabs]');
  let activeTab = null;
  document.addEventListener('tabby', e => {
    // notify activeTab and editor
    activeTab = e.detail.tab.hash.substring(1)
    editors[activeTab].focus()

    // update tab layout
    const index = tabLayout.indexOf(activeTab)
    if (index > -1) {
      tabLayout.splice(index, 1)
    }
    tabLayout.unshift(activeTab)
  }, false)

  const openNewQuery = (content, name) => {
    var tabList = document.querySelector('[data-tabs]')
    var tabPages = document.querySelector('.pages')

    var newContent = tabTemplate.cloneNode(true)
    const tabId = `tab-${tabCount++}`
    newContent.setAttribute('id', tabId)

    var li = document.createElement('li')

    var a = document.createElement('a')
    a.setAttribute('data-tabby-default', true)
    a.setAttribute('href', `#${tabId}`)
    a.innerText = name ? name : `Untitled-${tabCount}`

    var closer = document.createElement('span')
    closer.classList.add('close')
    closer.innerHTML = '&times;'

    li.appendChild(a)
    li.appendChild(closer)

    const tabItems = tabList.getElementsByTagName('a');

    if (tabItems.length > 0) {
      for (let i = 0; i < tabItems.length; i++) {
        const element = tabItems.item(i);
        if (element.getAttribute('data-tabby-default')) {
          element.removeAttribute('data-tabby-default')
        }
      }
    }

    tabList.appendChild(li)
    tabPages.appendChild(newContent)

    tabs.setup()

    // editor
    const editorElement = newContent.getElementsByClassName('code-editor')[0]
    var editor = CodeMirror(editorElement, {
      mode: 'text/x-sqlite',
      lineNumbers: true,
      value: content,
    });

    /**
     * @param {CodeMirror.Editor} e 
     * @param {*} c 
     */
    function onChange(e, c) {
      const { undo, redo } = e.historySize()

      if (undo === 0) {
        undoBtn.setAttribute('disabled', 'true')
      } else if (undoBtn.getAttribute('disabled') !== null) {
        undoBtn.attributes.removeNamedItem('disabled')
      }

      if (redo === 0) {
        redoBtn.setAttribute('disabled', 'true')
      } else if (redoBtn.getAttribute('disabled') !== null) {
        redoBtn.attributes.removeNamedItem('disabled')
      }
    }

    editor.on('change', onChange)
    editor.on('focus', onChange)

    // register editor
    editor.focus()
    li.scrollIntoView(tree)
    editors[tabId] = editor;
    // notify active tab
    activeTab = tabId;
    tabLayout.push(tabId)

    closer.addEventListener('click', () => {

      tabLayout.splice(tabLayout.indexOf(activeTab), 1)

      // Close tab
      tabList.removeChild(li)
      tabPages.removeChild(newContent)
      delete editors[tabId]
      tabs.setup()

      if (tabLayout.length > 0 && activeTab === tabId) {
        const previousTab = tabLayout.shift()
        tabs.toggle(`#${previousTab}`)
        console.log(`Toggled ${previousTab}...`)
      }
    })

    const resultGrid = agGrid.createGrid(
      newContent.getElementsByClassName('results')[0],
      gridOptions
    );

    const setColumns = (columns) => {
      resultGrid.setGridOption('columnDefs', columns)
    }

    const setData = (data) => {
      resultGrid.setGridOption('rowData', data)
    }

    newContent.getElementsByClassName('query-btn')[0].addEventListener('click', async () => {
      if (databse) {
        const content = editor.getValue()
        try {
          const result = await runQuery(content)

          console.log(result)
          if (result && result.data && result.data.length > 0) {
            setColumns(result.fields.map(field => ({ field, headerName: field })))
            setData(result.data)

            // TODO: Add result.query to history... 
          }
        } catch (e) {
          console.error(e)
        }
      }
    })
  }

  document.getElementById('new-query-btn').addEventListener('click', () => openNewQuery(''))
  document.getElementById('open-sql').addEventListener('click', async () => {
    const result = await openFile()
    if (result) {
      openNewQuery(result.content, result.name)
    }
  })

  // --- MAIN ACTIONS ---
  const undoBtn = document.getElementById('undo-btn')
  const redoBtn = document.getElementById('redo-btn')

  undoBtn.addEventListener('click', () => {
    if (activeTab) {
      editors[activeTab].undo()
    }
  })

  redoBtn.addEventListener('click', () => {
    if (activeTab) {
      editors[activeTab].redo()
    }
  })

  // --- TREEVIEW ---

  // const tableList = document.querySelector('#table-list')
  var tree = createTree('table-list', 'white');
  tree.drawTree()

  document.querySelector('#new-database').addEventListener('click', async () => {
    const result = await openDB()
    if (result) {
      databse = result

      // remove all children
      tree.childNodes.length = 0;
      tree.drawTree()

      const dbPath = result.path
      const dbName = result.name
      document.querySelector('.sidebar legend').innerHTML = `${dbName} Tables`

      for (var table_data of result.data) {
        const table = tree.createNode(table_data.name, false, './assets/svg/table.svg', null, null, null);
        const columns = tree.createNode('Columns', false, './assets/svg/column.svg', table, null, null);
        const indexes = tree.createNode('Indexes', false, './assets/svg/folder.svg', table, null, null);

        for (var schema of table_data.schema) {
          tree.createNode(`${schema.name} <span class='fade'>:${schema.type}</span>`, false, schema.pk === 1 ? './assets/svg/primary-key.svg' : '', columns, null, null)
        }

        for (var index of table_data.indexes) {
          tree.createNode(index.name + (index.unique === 1 ? '*' : ''), false, '', indexes, null, null)
        }
      }

      if (tabLayout.length === 0 || Object.keys(editors).length === 0) {
        openNewQuery('')
      }
    }
  })
})
