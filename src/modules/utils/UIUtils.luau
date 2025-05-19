local UIUtils = {}

--- Updates a page label with the current page information.
-- @param pageLabel TextLabel
-- @param currentPage number
-- @param pageCount number
function UIUtils.updatePageLabel(pageLabel: TextLabel, currentPage: number, pageCount: number)
    pageLabel.Text = string.format("%d / %d", currentPage, pageCount)
end

return UIUtils
