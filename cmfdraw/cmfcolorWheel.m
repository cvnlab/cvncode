function [rgbimg] = cmfcolorWheel(xcenter,ycenter,radius,rgbimg,cmap)
%Circle Legend
%Calculate circle coordinates
%center at 900,1001
coordsCirc = [];
for x = (xcenter-radius):(xcenter+radius)
    for y = (ycenter-radius):(ycenter+radius)
        if (x-xcenter)^2 + (y-ycenter)^2 <= radius^2
            coordsCirc(1,end+1) = x;
            coordsCirc(2,end) = y;
        end
    end
end

%Convert to polar coordinates
for i = 1:length(coordsCirc)
    coordsPolar(1,i) = atan2d(coordsCirc(1,i) - xcenter,coordsCirc(2,i) - ycenter);
    coordsPolar(1,i) = -coordsPolar(1,i);
    if (coordsPolar(1,i) <= 1)
        coordsPolar(1,i) = coordsPolar(1,i) + 360;
    end
    coordsPolar(2,i) = (sqrt((coordsCirc(1,i)-xcenter)^2 + (coordsCirc(2,i)-ycenter)^2)/10);
end

%Check whether polar angle or eccentricity

%Polar Angle
for i = 1:length(coordsCirc)
    if(coordsPolar(1,i) >= 360)
        coordsPolar(1,i) = 360;
    end
    s = round(coordsPolar(1,i));
    rgbimg(coordsCirc(1,i),coordsCirc(2,i), 1) = cmap(s,1);
    rgbimg(coordsCirc(1,i),coordsCirc(2,i), 2) = cmap(s,2);
    rgbimg(coordsCirc(1,i),coordsCirc(2,i), 3) = cmap(s,3);
end