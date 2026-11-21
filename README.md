# Causatz v1.0



Light drawing program (ersatz Photon mapper) to bake caustics from rendered image.



#### USE CASES:



If you want to render a still image of a glass or other refractive (or glossy) object (diamond, water, etc.), or an animation where neither the light or the object moves, this program is designed to take an image rendered from a light source, and draw a photon on a new target image for each pixel on said render. If done correctly (as covered below), this will result in WAY clearer and more accurate-looking caustics than any path tracer can ever dream of, which when imported back onto the original diffuse surface in Blender, will match the object perfectly in place.



#### WORKFLOW:



* Step 1. Select the glass object and the surface you want to have caustics. Copy these objects (ctrl + C). In the top right, create a new Scene ("Caustics"), and paste these objects into it. This will make it easier to experiment and then revert back to your original setup if needed.



* Step 2. Snap Camera to the Light - Start with your Blender scene (or whatever 3D suite you use, but the workflow won't be the same) where you want to have caustics. Add a new camera. Set it as Active, select both the camera THEN the light, and press Shift + S. Click on "Selection to Active" to snap to the last object selected.



* Step 3. Point the camera to the Glass and zoom in. To do that, select the camera, and rotate on Global Z and Local X (press R and then X twice. Switch to the Camera tab in the Properties 	panel and change the Field of View to zoom in, as well as the Render Dimensions under the Output tab to fit the image dimensions to the glass. You want it to take close to as much screen space as possible in the render.



Speaking of Resolution, you want to set that very high (at least 4K, depending on your aspect ratio from earlier), since each pixel on this image will contribute a Photon to the final result. Also disable Denoising. (NOTE: Do not use an image larger than 16384px in either dimension, as Godot will not import it. Regardless also, trying to render an image too large may crash Blender.



* Step 4. Give the Glass a new Material ("Refraction"). Change Surface to Refraction BSDF (this is pure refraction, whereas the Glass shader has reflections as well (meaning the caustics would appear as morphed somewhere in between reflective and refractive). If you want to cast REFLECTIVE caustics instead (as if the object is Metal), use the "Glossy BSDF" shader.



* Step 5. Select the Ground (whatever the glass sits on), and make sure the UV coordinates of the object are not overlapping and are within the UV canvas (the square in the middle of the UV area showing either an Image or a Checkerboard). If you need the original UV map, add another one just for the Caustics.



* Step 6. Give the Ground a new Material ("Surface"). Go to the Shading tab to work with shader nodes. Add a Light Path node and a UV Map node. (If using a separate map to bake Caustics, select that one in the Material.) Multiply the UV map with the "Is Transmission Ray" from the Light Path (when light goes through glass). (If using shiny and refractive objects in the same shot, add the "Is Glossy Ray" and use that instead.) Also multiply it with Blue, and add that to the UV from before.



* Step 7. Go to your Render tab and set the sampling amount to 1. Any higher is unnecessary, as sampling each pixel 2 times would average their values, not increase the amount of pixels, each of which act as one photon. Render the image. You should have what looks something like a normal map. Now save the image (Image > Save) into the Causatz project folder as an EXR, and in Raw color space, so that the image values in your render are respected with no color transformations applied to it. Now you have an image containing data about where on the surface photons hit.



#### USING CAUSATZ:



Download this project, and then download Godot 4.7 or later and open that. In Godot, navigate to the project and select "Edit". The project contains by default one EXR image rendered using the above steps, which is fairly low quality for the sake of download size. If you were to press Play now, it will run this image through and create a caustic map, but it will look like it's throwing white dots everywhere, because the example image contains way less pixels than what I was testing with. This is why you want to render a higher resolution image - more pixels there means more photons to draw, and therefore, clearer caustics.



Open the project Scene (Causatz_Base/Sprite2D.tscn). Select the "DestImage" node to see settings for configuring Causatz in the Inspector. To see this working, drag the image you just rendered into the "Source Image" script variable, which appears at the top of the Inspector. Press "Play" on the top right of Godot. This will start the program, and at first the image should look black, but then the program will run through a few rows of your source image at a time, depending on how long each row takes to draw. You should gradually start to see the caustics forming. Once the process completes, you should see a message in the Output window in Godot, telling you it's done drawing. As that message also says, if you change any of the settings under the "Colors" subgroup, you will then have to press the Right arrow to update them (although running the project again also works).



#### IMPORT BACK TO BLENDER:



Pressing ENTER will then save that image into your Project folder under the name specified in your "imageName" string variable in the Inspector. If you try to re-save under the same name then it may not work; in that case just change the Image Name variable to something else.



Once you have this image, right-click on it in the project (FileSystem tab), and select "Show in Explorer". In Blender, go back to your original Scene and select the ground. In the material (assuming you are using Principled BSDF setup), plug the image into the Emission socket (color). Now, because of the way this program works, how bright these should be is anyone's guess. So if it looks incorrect (as if it doesn't match the light), or you want artistic license, change the Emission Strength to suit.



NOTE: If there is enough contrast or dark area in the Diffuse Color (in my example, I used the Checker Texture), the caustics may look pasted over. This is because when light goes through glass and hits things, dark areas still absorb light. So to make them look integrated, add a Mix node and drop it in between the image and the Emission color. Set this to Multiply, and plug the diffuse color into the "B" input (second color). You can now adjust the Factor value if you want this to be less intense (which may not look accurate, but can be good if you want caustics more visible just for show).





#### 

#### VARIABLES



* Source Image: Light POV that will be used to draw caustics.
* Target Size: The size of image that will be created as a target to draw the caustics to it.



* Caustics Color: Allows you to tint caustics (e.g. setting this to Red will turn caustics Red, as if the glass is Red). If your object is tinted, you can select its color in your 3D software, copy the Hex Code, and paste it into Godot.
* Caustics Exposure: Multiplies the brightness of target image. (The actual target image is 16-bit, so the value of a photon is 1 / 65536, which gets scaled and converted to sRGB in order to display the result, accounting for source and target resolutions.)
* Enable Clipping: Clips out low-light areas, where there are more stray photons.
* Clip Min: Smallest brightness drawn to final image from the target.
* Clip Fade: Softens clipping effect. Clip fade of 1 extends all the way to black. Example: If Clip min is 0.5, and Clip Fade is 0.25, a value of 0.25 will be fully clipped, and a value of 0.375 will be darkened by half.



Note on DE-ARTIFACTING - Deartifacting uses the offset between the current photon position and the previous one (the "Row Travel", as I will refer to it), to try to detect how concentrated caustic lighting is in that area, and blur accordingly. This can help with the swirly line artifacts you might see from the trajectory of the source rows/columns, at least in some areas. However, it can also create glowy-looking caustics, and if you set the Blur too high, you may start to see a rotated grid pattern in some areas. Adaptive blurring quality is planned, so maybe in the future this will work better, but for now, this feature is highly experimental. A more accurate way to eliminate artifacting is to use Passes, which will be covered below.





* Quality: Number of photon samples drawn to target for each source pixel = x \* y. Example: If X = 3 and Y = 5, 15 photons will be drawn. If quality is set to (1, 5), the blur will go along the same direction the row is traveling. Whereas with (5, 1), it will be perpendicular. (5, 5) is simply a rotated box blurring effect whose size is dependent on the row travel for each photon.
* Blur Mult: Scale for the artifact blurring, as multiplied by Row Travel. In sparser areas, too much blur may result in a visible grid pattern. Again, adaptive blur quality is a planned feature for later.



PASSES - Having a high-resolution photon coordinate map can only go so far, as higher resolution images can crash whilst rendering. Plus, there's no randomization within each pixel as to where on the glass the photons will hit. A "pass" is basically an image, out of several, all of which contribute to the resulting caustics map. The program will run through all the passes, and contribute each as photons to the target image.

Set name of the output frames to "Pass", and change the output folder to the "Passes" folder in Causatz. That way your animation frames will output as "Pass0000", then "Pass0001", "Pass0002", and so on. You also now don't need to render high-res images, because you can render an animation as long as you want to get hundreds of passes. This will also help you to get more randomization of sampled positions on the sub-pixel level. 

Speaking of which, the camera needs to face in a slightly different direction every frame, as each pixel in the image has to be in a different position on the glass. To do this, go to the Animation Tab, then change the animation view (where it says "Dope Sheet") to be the Graph Editor. Select the camera and add a key frame under "Delta Rotation" in the Object panel. Now in the Graph editor, select the "Modifiers" Tab on the right side. Add a Noise modifier to both the X and Y component of the delta rotation, and change the Phase value on one of them. The rotation should not be in sync on both axes. Set the Strength to something low enough that the camera is jittering around slightly, but the glass is not going out of frame. Render an animation, and you get variations with slightly different pixel positions on screen. 

In Godot, select the DestImage node and go to the "Multipass" section of the script variables. Set "Passes" to the number of passes you rendered in your animation.



* Passes Folder name: The name of the folder which Causatz will load passes from.
* Passes: The number of passes in this folder.
* Pass 1 Number: The numbering for the first pass (the first frame of your animation). Example: If start of Blender frame range is set to 256, set this to 256. It will automatically load the file named "Pass0256" based on Blender's name conventions for output frames.



#### LIMITATIONS:



If the glass moves, the caustics no longer match the objects and will therefore have to be redone. Since this workflow is entirely manual, trying to use it every frame in an animation would defeat its purpose. Beyond that, you cannot tint individual objects or have an object's detail casting shadows in the caustics, and since this program uses a zoomed-in frame of whatever size the object is to make use of image space, it's anyone's guess as to how bright the caustics should be. In cases where you need animations of the light or glass moving, or you want accurate lighting, use a rendering engine which has a photon mapper or caustics solver, like Appleseed or Corona.



Anyway, this was really just an experiment if nothing else. I hope someone finds it interesting or useful for something though.







PLANNED FEATURES:



Per-pass Hue (dispersion)

Adaptive De-artifact quality (based on estimated sparseness)

Textured caustics (based on B channel)

