function [rgbimg,hmapfig,hLines] = cmfupdateIMG(todo,img,hmapfig,swapFlag,cmap,cmapRH,newFig,lineIndex)
rgbimg = img;
if(nargin == 7)
    lineIndex = 0;
end
hLines = [];
%Apply lineMasks
% % % loader = load(strcat('/home/stone-ext4/generic/Dropbox/hcp7tret-cmf/lineData/',num2str(todo),'/results.mat'));
% % % for i = 1:24
% % %     if(~isempty(loader.xyline{i}))
% % %         xyline = loader.xyline{i};
% % %         for j = 1:length(xyline);
% % %             rgbimg(xyline(j,2), xyline(j,1),:) = 0;
% % %             %Experimental: Color (1) pixels above and below each line pixel
% % %             rgbimg(xyline(j,2), xyline(j,1) + 1,:) = 0;
% % %             rgbimg(xyline(j,2), xyline(j,1) - 1,:) = 0;
% % %             %Experimental2: Color (1) pixels next to each line pixel
% % %             rgbimg(xyline(j,2) + 1, xyline(j,1),:) = 0;
% % %             rgbimg(xyline(j,2) - 1, xyline(j,1),:) = 0;
% % %         end
% % %     end
% % % end

%Check whether polar angle or eccentricity

if (swapFlag == -1)
    %Polar Angle
    rgbimg = cmfcolorWheel(900,880,75,rgbimg,cmap);
    rgbimg = cmfcolorWheel(900,1122,75,rgbimg,cmapRH);
end

if (swapFlag == 1)
    %Eccentricity
    %Make bar
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
end

%show the map
if(isempty(hmapfig))
    hmapfig = figure;
else
    if (newFig)
        close(figure(hmapfig));
        hmapfig = figure;
    else
        figure(hmapfig);
        clf;
    end
end
figure(hmapfig)
himg = imshow(rgbimg);
axis image tight

if(swapFlag == 1)
    %Define points from length
    for i = [0.5 2 7]
        j = 1 + round(i*(255/12));
        text(850+(25*i),850,num2str(i),'Color','k','HorizontalAlignment','center','FontWeight','bold','BackgroundColor',[cmap(j,1) cmap(j,2) cmap(j,3)]);
    end
    for i = [1 4]
        j = 1 + round(i*(255/12));
        text(850+(25*i),950,num2str(i),'Color','k','HorizontalAlignment','center','FontWeight','bold','BackgroundColor',[cmap(j,1) cmap(j,2) cmap(j,3)]);
    end
end

%Use line(x,y) to draw
[status,userName] = unix('whoami');
userName = userName(1:end-1);
userName = getpref('ROIGUI','user',userName);
loader = load(strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName,'/',num2str(todo),'/results.mat'));
for i = 1:24
    if(i == lineIndex)
        color = 'w';
    else color = 'k';
    end
    if(~isempty(loader.xyline{i}))
        xylineCell = loader.xylineCell{i};
        for j = 2:length(xylineCell)
            xyline = xylineCell{j};
            lineStyles = xylineCell{1};
            switch lineStyles(j-1)
                case 0
                    style = '-';
                case 1
                    style = '--';
            end
            xylinetemp = 1000 - xyline;
            xyline(:,1) = 1000 - xylinetemp(:,2);
            xyline(:,2) = 1000 - xylinetemp(:,1);
            hLines(end+1) = line(xyline(:,2),xyline(:,1),'LineWidth',2,'LineStyle',style,'Color',color);
        end
    end
end


return

