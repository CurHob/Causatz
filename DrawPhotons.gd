extends Sprite2D

var currentRow := 0
var lastShadow := 0.0

var imgFinished := false
var loadNextPass := true

@export var sourceImage : Texture2D
var source : Image
@export var targetSize := Vector2i(2048, 2048)
@export var imageName := "Caustics"
@export_subgroup("Color")
@export var causticsColor := Color(0.824, 0.941, 1.0, 1.0)
@export var causticsExposure := 1.0
@export var enableClipping := false
@export var clipMinimum := 0.004
@export_range(0,1) var clipFade := 0.2
@export_subgroup("Deartifact (Slow, experimental)")
@export var quality := Vector2i(10,10)
@export var blurMult := Vector2(50,50)
var realMin : float
var totalPxInv : float

@export_subgroup("Performance")
@export_range(0,1000) var drawSpeed := 20
@export_range(1,60) var minFrameRate := 60
@export_subgroup("Multipass")
@export var passesFolderName := "Passes"
@export var passes := 16
@export var pass1Number := 0
var passIndex := 0
var currentPass : Image

var dest : Image
var final : Image
var photon := Color(1.1/65536, 1.1/65536, 1.1/65536, 1) #Minimum brightness representable in a 16-bit image
var power := 0.5
var tx : ImageTexture

func _ready() -> void:
	print("Causatz v1.1")
	realMin = lerp(clipMinimum, 0.0, clipFade)
	source = sourceImage.get_image()
	totalPxInv = causticsExposure / (source.get_width() * source.get_height() * passes * max(1, quality.x) * max(1, quality.y))
	print("Inverse Area: ", totalPxInv)
	dest = Image.create(targetSize.x, targetSize.y, false, Image.FORMAT_RGB16)
	final = Image.create(targetSize.x, targetSize.y, false, Image.FORMAT_RGB8)
	tx = ImageTexture.create_from_image(dest)
	texture = tx

func _process(delta: float) -> void:
	#Load next pass once current one is finished
	if loadNextPass:
		if passes > 1:
			var prependage : String #Adhere to Blender's 4-digit frame naming conventions (0001, 0002, 0003...)
			for c in 4 - str(pass1Number).length():
				prependage += "0"
			prependage += str(pass1Number + passIndex)
			currentPass = load("res://" + passesFolderName + "/Pass" + prependage + ".exr").get_image()
		else: 
			currentPass = sourceImage.get_image()
		loadNextPass = false
	
	var passHeight = currentPass.get_height()
	#Account for size of both source and dest image (and brightness setting)
	
	var frameStartTime := Time.get_ticks_msec()
	for row in drawSpeed: #Draw a maximum of this number of rows from light POV image on current frame
		print("DRAWING ROW")
		
		if currentRow >= currentPass.get_height():
			break
		var rowSectionStarted := false
		var lastCoord : Vector2
		for x in currentPass.get_width(): #Loop over 1 row on light POV image
			var sourceColor := currentPass.get_pixel(x, currentRow) #Get pixel on light POV image
			#Then, convert light POV pixel to photon coordinate on target image
			var photonCoord := Vector2(sourceColor.r * targetSize.x, (1 - sourceColor.g) * targetSize.y)
			if !sourceColor.b > 0.9:
				continue #Out-of-bounds pixel positions somehow choke the program if not manually checked (?!?!)
			var ofst := photonCoord - lastCoord
			var perp = Vector2(ofst.y, -ofst.x)
			#print(ofst, " | ", perp)
			
			#Use multiple photons to blur less concentrated caustics areas
			#The more photonCoord moved, the sparser the caustics
			#If quality dimension is NOT more than 1, then center the position in that dimension
			for p in max(1, quality.x): 
				for q in max(1, quality.y): 
					#Create value scaled on division, but for now just multiply by blur
					#TO-DO: Adaptive photons quality
					var samplePos = Vector2.ZERO if quality.y < 2 else lerp(-ofst, ofst, float(q) / (1 - quality.y)) * blurMult.y
					samplePos += Vector2.ZERO if quality.x < 2 else lerp(-perp, perp, float(p) / (1 - quality.x)) * blurMult.x
					if quality.x == 1:
						samplePos.x = 0
					if quality.y == 1:
						samplePos.y = 0
					var sampleCoord = photonCoord + samplePos
					#If out of bounds, continue
					if sampleCoord.x < 0 or sampleCoord.x >= targetSize.x or sampleCoord.y >= targetSize.y or sampleCoord.y < 0:
						continue
					dest.set_pixelv(sampleCoord, dest.get_pixelv(sampleCoord) + (photon)) #Add photon to target image (min. 16-bit value)
					drawPx(sampleCoord)
			
			lastCoord = photonCoord
		currentRow += 1
		if Time.get_ticks_msec() - frameStartTime > 1000.0 / minFrameRate: #Stop drawing if frame is too slow
			break
	
	#Mark current pass as being finished drawing
	var imgJUSTfinished = false
	if currentRow == passHeight:
		if passIndex < passes and passes > 1:
			passIndex += 1
			currentRow = 0
			loadNextPass = true
		else: 
			imgFinished = true
			imgJUSTfinished = true
			print("Finished Drawing Image. Press ENTER to save. Press RIGHT to see changes.")
			currentRow += 1
	
	if (imgFinished and Input.is_action_just_pressed("ui_right")) or imgJUSTfinished:
		for x in targetSize.x:
			for y in targetSize.y:
				drawPx(Vector2(x, y))
	if Input.is_action_just_pressed("ui_accept"):
		final.save_png("Caustics.png")
		print("IMAGE SAVED IN PROJECT AS [" + imageName + "]")
	
	tx = ImageTexture.create_from_image(final)
	texture = tx
	
func drawPx(dstCoord : Vector2):
	var destPx : Color = dest.get_pixel(dstCoord.x, dstCoord.y) * causticsColor * totalPxInv * targetSize.x * targetSize.y
	#if destPx == Color.BLACK:
	#	continue
	destPx = destPx.linear_to_srgb()
	if destPx.v < realMin:
		return
	var clipMult = min((destPx.v - realMin) / (clipMinimum - realMin), 1)
	clipMult = smoothstep(0, 1, clipMult)
	if !enableClipping:
		clipMult = 1
	final.set_pixel(dstCoord.x, dstCoord.y, destPx * clipMult)
