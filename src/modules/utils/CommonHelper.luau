local AssetService = game:GetService("AssetService")

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

function CommonHelper.createEditableImage(size: Vector2)
    local editableImage = AssetService:CreateEditableImage({Size = size})
    CommonHelper.addEditableImageMemoryUsage(editableImage)
    return editableImage
end

function CommonHelper.destroyEditableImage(editableImage: EditableImage)
    if editableImage then
        CommonHelper.substractEditableImageMemoryUsage(editableImage)
        editableImage:Destroy()
    end
end

return CommonHelper
