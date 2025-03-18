function doGet(e) {
  const ss = SpreadsheetApp.openById("..........")
  const sheet = ss.getSheetByName("Stats")

  // Get stats/limit
  const stats = e.parameter.stats.replace(/\\;/g, "#!sc!#").split(";").map(x => x.replace(/#!sc!#/g, ";"))
  const limit = e.parameter.limit

  // Append to sheet
  sheet.appendRow(stats)

  // Copy formatting from row before last to last data row
  const lastColumn = sheet.getLastColumn()
  const lastRow = sheet.getDataRange().getLastRow()
  const range = sheet.getRange(lastRow - 1, 1, 1, lastColumn)
  range.copyFormatToRange(sheet, 1, lastColumn, lastRow, lastRow)

  // Limit rows
  if (limit > 0) {
    const tooManyRows = sheet.getDataRange().getLastRow() - limit - 1
    if (tooManyRows > 0) sheet.deleteRows(2, tooManyRows)
  }

  return HtmlService.createHtmlOutput()
}
