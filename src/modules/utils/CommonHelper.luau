local CommonHelper = {}

local editableImageMemoryUsage = 0

function CommonHelper.addEditableImageMemoryUsage(image: EditableImage)
    editableImageMemoryUsage = editableImageMemoryUsage + image.Size.X * image.Size.Y * 4
end

function CommonHelper.substractEditableImageMemoryUsage(image: EditableImage)
    editableImageMemoryUsage = editableImageMemoryUsage - image.Size.X * image.Size.Y * 4
end

function CommonHelper.getEditableImageMemoryUsage()
    return editableImageMemoryUsage / 1024 / 1024
end

return CommonHelper
