function [rgbimg] = cmfaddLegend(rgbimg,type)
switch type
    case 1
        %Polar Angle
        cmap = cmfanglecmap;
        cmapRH = cmfanglecmapRH;
        rgbimg = cmfcolorWheel(900,880,75,rgbimg,cmap);
        rgbimg = cmfcolorWheel(900,1122,75,rgbimg,cmapRH);
    case 2
        cmap = cmfecccmap;
        coordsBar = [];
        for j = 875:925
            for i = 1:300
                coordsBar(1,end+1) = j;
                coordsBar(2,end) = 851 + i;
            end
        end
        for i = 1:length(coordsBar)
            %rgbimg(coordsBar(1,i),coordsBar(2,i),:) = 0;
            s = round((coordsBar(2,i) - 851) * (256/300));
            if(s==0)
                s = 1;
            end
            rgbimg(coordsBar(1,i),coordsBar(2,i), 1) = cmap(s,1);
            rgbimg(coordsBar(1,i),coordsBar(2,i), 2) = cmap(s,2);
            rgbimg(coordsBar(1,i),coordsBar(2,i), 3) = cmap(s,3);
        end
        %Define points from length
        for i = [0.5 2 8]
            j = 1 + round(i*(255/12));
            text(850+(25*i),850,num2str(i),'Color','k','HorizontalAlignment','center','FontWeight','bold','BackgroundColor',[cmap(j,1) cmap(j,2) cmap(j,3)]);
        end
        for i = [1 4]
            j = 1 + round(i*(255/12));
            text(850+(25*i),950,num2str(i),'Color','k','HorizontalAlignment','center','FontWeight','bold','BackgroundColor',[cmap(j,1) cmap(j,2) cmap(j,3)]);
        end
end