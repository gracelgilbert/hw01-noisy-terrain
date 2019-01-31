# Grace Gilbert (gracegi)

## Demo Link
![https://gracelgilbert.github.io/hw01-noisy-terrain/](https://gracelgilbert.github.io/hw01-noisy-terrain/)

![](TopImage.png)

## External Resources
I used the following source to help calculate the gradient of my height map terrain:
![https://gamedev.stackexchange.com/questions/89824/how-can-i-compute-a-steepness-value-for-height-map-cells](https://gamedev.stackexchange.com/questions/89824/how-can-i-compute-a-steepness-value-for-height-map-cells)

## Inspiration and Reference Images
I was largely inspired by the Atacama Desert in Chile. I like how the mountains vary, ranging from flatter plateaus to pointed peaks. I also particularly liked the contrast of having the icy salt on the lower elevation flats, rather than the typical snow at the peaks of the mountains. These features of the desert, along with others, are ones I tried to incorperate into my terrain:
![](atacama1.jpg)
![](Atacama2.jpg)


## Implementation
### Height Map
I combined three noise functions to create the height map of the terrain.  
- For the sharper peaks, I used a simple FBM and raised the output value to the 8th power to get steeper slopes and flatter flats.  
- For the plateau heightmap and placement, I used a Worley Noise based FBM at a larger scale. The Worley Noise helped create natural looking pockets of flatter land surrounded by the plateaus. 
- To flatten the tops of the plateaus, I bound the height map by a maximum height. I generated this maximum height using pure Worley Noise, which created a smooth, subtly rounded surface at the tops of the plateaus rather than a flat plane. The user can adjust the scale of the Worley Noise maximum height to raise and lower the plateaus. 
The combination of these three noise functions helped me achieve the terrain variety I liked in the Atacama Desert. 

INSERT IMAGE OF HEIGHTMAP AND TERRAIN AT TWO DIFFERENT HEIGHTS

### Ground Texture
For the ground texture, I created various textures and then used maps to combine them. 
- The base material is the red earth texture. To make this, I have a red color that is darkened in areas using FBM. I also used the inverses of two frequencies of Worley based FBM to create the crackly pattern in the earth. This pattern is scaled by the gradient so that it only appears on flatter areas. 

- Layered on top of the red texture is a dusty, dark gray green tone. This texture is masked by an FBM, as well as the elevation and gradient of the terrain. The result is that the dark gray appears towards the tops of the plateaus as well as in flatter areas along the sides of mountains, creating a natural color shift on the elevated terrain. 

