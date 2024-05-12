function doGet(e) {
  const ss = SpreadsheetApp.openById("..........")
  const sheet = ss.getSheetByName("Stats")

  // Get stats/limit
  const stats = e.parameter.stats.split(";")
  const limit = e.parameter.limit

  // Append to sheet
  sheet.appendRow(stats)

  // Limit rows
  if (limit > 0) {
    const tooManyRows = sheet.getLastRow() - limit - 1
    if (tooManyRows > 0) sheet.deleteRows(2, tooManyRows)
  }

  return HtmlService.createHtmlOutput()
}
