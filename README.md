ov7660-object-tracker
=====================

Object tracking using an ov7660 camera.
The aim of this project is to implement an object tracking algorithm, leading to control of two servo motors mounted on an arm.
The two servo motors will control X and Y axis, Yaw and Pitch.

The implementation first captures the data, filters it using a gaussian filter to clean some noise and then into a sobel filter to find the edges.
Finally a tracking algorithm is empliyed trying to keep the current object inside a rectangle.
The center of the triangle is compared against the middle of the screen and a delta is calculated. 

This delta is transformed to coordinates of the servo resultions and fed to the pitch and yaw servos.

