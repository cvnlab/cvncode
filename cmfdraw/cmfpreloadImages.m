a2 = matchfiles('/stone/ext4/kendrick/HCP7TFIXED/??????');
subjects = cellfun(@(x) stripfile(x,1),a2,'UniformOutput',0)';
subjects = subjects(1:end-3);

%todo = sort(floor(1+(rand(5,1)*180)));
%todo = 1:181;
todo = 181;
for i = 1%:181;
[rgbimg1 L mappedvalsPA] = cmfpilotRun(todo(i),1,0);
[rgbimg2 L mappedvals] = cmfpilotRun(todo(i),3,0);
rgbimgPA = horzcat(rgbimg1(:,1:1001,:),rgbimg2(:,1002:2000,:));
[rgbimgECC L mappedvalsECC] = cmfpilotRun(todo(i),2,0);
[curvatureOnly L mappedvals] = cmfpilotRun(todo(i),4,0);
% imwrite(rgbimgPA,strcat('/home/stone-ext4/generic/Dropbox/hcp7tret-cmf/Selected_Examples/Example:',num2str(i),'_Subject:',num2str(todo(i)),'_PolarAngle_NoAtlas.png'));
% imwrite(rgbimgECC,strcat('/home/stone-ext4/generic/Dropbox/hcp7tret-cmf/Selected_Examples/Example:',num2str(i),'_Subject:',num2str(todo(i)),'_Eccentricity_NoAtlas.png'));
% imwrite(rgbimgCurv,strcat('/home/stone-ext4/generic/Dropbox/hcp7tret-cmf/Selected_Examples/Example:',num2str(i),'_Subject:',num2str(todo(i)),'_Curvature_NoAtlas.png'));

pathname = strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/lineData/',subjects{todo(i)},'/');
file2save = fullfile(pathname,'cache.mat');
save(file2save,'mappedvalsPA','mappedvalsECC','L','rgbimgPA','rgbimgECC','curvatureOnly')

[rgbimg1 L mappedvals] = cmfpilotRun(todo(i),1,1);
[rgbimg2 L mappedvals] = cmfpilotRun(todo(i),3,1);
rgbimgPA_Atlas = horzcat(rgbimg1(:,1:1001,:),rgbimg2(:,1002:2000,:));
[rgbimgECC_Atlas L mappedvals] = cmfpilotRun(todo(i),2,1);
[curvatureOnly_Atlas L mappedvals] = cmfpilotRun(todo(i),4,1);

save(file2save,'rgbimgPA_Atlas','rgbimgECC_Atlas','curvatureOnly_Atlas','-append')
fprintf(num2str(i));
end

