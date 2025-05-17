local AssetService = game:GetService("AssetService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local ClientState = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState"))

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

function CommonHelper.renderImage(
    imageLabel: ImageLabel, 
    imageData: {ImageBuffer: buffer, 
                ImageResolution: Vector2, 
                Width: number, Height: number}) 
:EditableImage?
    local imageResolution = imageData.ImageResolution or Vector2.new(imageData.Width, imageData.Height)
    local src = CommonHelper.createEditableImage(imageResolution)

    -- If we can't create the editable image, we should return.
    if src == nil then
        return nil
    end

    local dest = CommonHelper.createEditableImage(imageLabel.AbsoluteSize) 

    -- If we can't create the editable image, we should return.
    if dest == nil then
        CommonHelper.destroyEditableImage(src)
        return nil
    end

    src:WritePixelsBuffer(Vector2.zero, imageResolution, imageData.ImageBuffer)
    local scale = Vector2.new(imageLabel.AbsoluteSize.X / imageResolution.X, imageLabel.AbsoluteSize.Y / imageResolution.Y)
    dest:DrawImageTransformed(
        Vector2.zero,                         -- put TOP‑LEFT at (0,0)
        scale,                                -- shrink
        0,                                    -- no rotation
        src,
        { PivotPoint = Vector2.zero, CombineType = Enum.ImageCombineType.Overwrite } )
    -- Destroy the source editable image to release memory.
    CommonHelper.destroyEditableImage(src)
    -- render the image .
    imageLabel.ImageContent = Content.fromObject(dest)

    return dest
end

function CommonHelper.unrenderCanvas(canvas: Model)
    CommonHelper.destroyEditableImage(ClientState.DrawingCanvas[canvas].editableImage)
    ClientState.DrawingCanvas[canvas].editableImage = nil
    ClientState.DrawingCanvas[canvas].rendered = false
end

function CommonHelper.renderToCanvas(canvas: Model, data: {imageData: {ImageBuffer: buffer, ImageResolution: Vector2, Width: number, Height: number}, rendered: boolean})
    local dest = CommonHelper.renderImage(
        canvas.PrimaryPart:FindFirstChild("CanvasGui"):FindFirstChild("DrawingImage"),
        data.imageData
    )
    -- If we successfully created the editable image, we should store it.
    if dest then
        ClientState.DrawingCanvas[canvas].editableImage = dest
        data.rendered = true
    end
end
return CommonHelper
