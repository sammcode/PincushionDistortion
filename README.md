# PincushionDistortion
An interactive pincushion distortion effect on iOS, built with SwiftUI.

### Notes
This was heavily inspired by Janum Trivedi's [Magnification Loupe](https://github.com/jtrivedi/MagnificationLoupe/tree/main). I used it as a reference for the Metal shader, as well as the spring animations using [Wave](https://github.com/jtrivedi/Wave).

The pincushion distortion is created by calculating the zoom offset for each pixel using it's distance from the center of the distortion and a [damped sine wave](https://en.wikipedia.org/wiki/Damping#Damped_sine_wave) function.

https://github.com/sammcode/PincushionDistortion/assets/58298401/edee75d7-ab68-4274-bb2c-38762515d24b

