function [hline, lineName] = cmfshowLines(todo,fig,lineIndex)
figure(fig)
hline = {};
%Use line(x,y) to draw
[~,userName] = unix('whoami');
userName = userName(1:end-1);
userName = getpref('ROIGUI','user',userName);
loader = load(strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName,'/',num2str(todo),'/results.mat'));
lineName = loader.labels{lineIndex};
for i = 1:24
    if (i ~= lineIndex)
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
                
                hline{end+1} = line(xyline(:,2),xyline(:,1),'LineWidth',2,'LineStyle',style,'Color','k');
            end
        end
    end
end
