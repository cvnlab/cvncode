function cvnanalyzePRF(hmv,datafiles,stimfiles,max_no_values,outputdir,subjid,flagmgz,foi)
%cvnanalyzePRF(hmv,datafiles,stimfiles,max_no_values,outputdir,subjid,flagmgz,foi)
%
%Performs PRF analysis independently per hemisphere and cortical depth in
%surface space using analyzePRF.m. The function loads the stimulus masks
%and loads and reshapes the data as required by analyzePRF.m (i.e. nvertices
%x nlayers x ntimepoints). It assumes that the loaded data are formatted
%as follows: ntimepoints x nlayers x nvertices; and that nvertices includes
%vertices values for left and right hemispheres (i.e. size(data,1) = number
%of left hemisphere vertices + number of right hemisphere vertices). It
%also assumes that the data.mat file loaded includes the following
%variables:
%
% 1.	data = data matrix (structured as indicated above)
% 2.	TR = scalar indicating data TR
% 3.	numlh = number of left hemisphere vertices
% 4.	numrh = number of right hemisphere vertices
%
%The PRF results are saved to one .mat file per hemisphere and layer in the
%directory specified by the 'outputdir' with the following filename:
%'subjid'_'hemishpere_name'_run'run_number'_layer'layer_number'_results_PRF.mat
%e.g. C0041_rh_run0102_layer6_results_PRF.mat.
%
%The PRF results may also be written into and .mgz overlay file
%(see flagmgz)
%
%NOTE i: number of data TR as to match stimulus TR
%NOTE ii: if the data total number of vertices exceeds max_no_values, PRF
%NOTE iii: it is assumed that the effective TR that is associated with
%          the datafiles and the stimfiles is exactly 1 second.
%analysis will be looped and the outputted results structure will be
%different from the original "results" structure outputted by analyzePRF.m:
%   the .noisereg field will not be saved
%   the .options field will only contain the .vxs and .hrf subfields
%
%calls upon analyzePRF.m and all its dependencies
%
%<hmv> cell vector or char containing the string 'lh', 'rh' or both. It
%indicates whether PRF analysis will be performed across left hemisphere,
%right hemisphere or both. If empty analysis will be performed across both
%hemispheres
%
%<datafiles> cell array of filenames (or a wildcard) containing the path to
%and the name of the files to be loaded.
%
%<stimfiles> cell array containing path to and filename of the stimulus
%masks to be loaded
%
%<max_no_values> max number of values to be analysed at once. If the total
%number of vertices in the data exceed this number, PRF analysis will be
%looped. NOTE Stone can handle in the region of approximately 400000
%vertices
%
%<outputdir> string containing the path where *resulsts_PRF.mat files
%will be saved. If the directory inputted does not exist it will be
%created.
%
%<subjid> string containing the subjid (i.e. the folder name for that
%subject).
%
%<flagmgz> scalar - either 1 or 0. If 1 the function will write .mgz
%overlay files independently per layer in the folder <outputdir>/mgz.
%This folder will be created if it does not already exist. The newly
%created .mgz files will be named as follows:
%'hemishpere_name'.'hemishpere_name'_run'run_number'_layer'layer_number'_results_PRF_'result_type'.mgz
%e.g. rh.rh_run0102_layer6_results_PRF_ang.mgz
%optional - if not provided or empty, default = 0
%
%<foi> scalar vector with values ranging from 1 to 10 indicating the field
%numbers of interest of the PRF - i.e. those that will be written into .mgz
%files (only relevant if flagmgz=1). Results structure as follows:
%
%1 ang
%2 ecc
%3 expt
%4 rfsize
%5 R2
%6 gain
%7 resnorms
%8 numiters
%9 meanvol
%10 noisereg
%
%optional - if not provided or empty, default is foi=[1 2 4 5];

outputdir=[outputdir,'/'];
if ~exist('flagmgz','var') || isempty(flagmgz)
    flagmgz=0;
end
if ~exist ('foi','var') || isempty(foi)
    foi=[1 2 4 5];
end
if ischar(datafiles)
    datafiles={datafiles};
end
datafiles=matchfiles(datafiles);
Nr=length(datafiles);
extnm=cell(1);
for ri=1:Nr
    tmpidx=(strfind(datafiles{1},'run'));
    extnm{1}(1+size(extnm{1},2):2+size(extnm{1},2))=...
        datafiles{ri}(tmpidx+length('run'):tmpidx+length('run')+1);
end
extnm=char(extnm);
extnm=['run',extnm];
stimulus = cell(length(stimfiles),1);
for sti=1:length(stimfiles)
    stimulus{sti}=loadmulti(stimfiles{sti},'stimulus');
end
if isempty(hmv)
    hmv={'lh';'rh'};
end
if ischar(hmv)
    hmv={hmv};
end
if length(hmv)==2
    hmv={'lh';'rh'};
    hmv1=[1,2];
    data=cell(Nr,1);
    for r=1:Nr
        tmpdata=matfile(datafiles{r});
        data{r}=single(permute(tmpdata.data,[3 2 1]));
    end
    numvalues=[tmpdata.numlh;tmpdata.numrh];
else
    if isequal(hmv,{'lh'})
        hmv1=1;
        data=cell(Nr,1);
        for r=1:Nr
            tmpdata=matfile(datafiles{r});
            numlh=tmpdata.numlh;
            data{r}=single(permute(tmpdata.data(:,:,1:numlh),[3 2 1]));
        end
        numvalues=numlh;
    else
        hmv1=2;
        data=cell(Nr,1);
        for r=1:Nr
            tmpdata=matfile(datafiles{r});
            numrh=tmpdata.numrh;
            numlh=tmpdata.numlh;
            data{r}=single(permute(tmpdata.data(:,:,1+numlh:numlh+numrh),[3 2 1]));
        end
        numvalues=tmpdata.numrh;
    end
end
if size(stimulus{1},3)~=size(data{1},3)
    error('number of simulus volumes does not match number of data volumes')
end
Nl=size(data{1},2);
for hm=hmv1
    if length(hmv)==2 && hm==2
        hm1=hm;
        nvrtc=numvalues(1);
    else
        hm1=1;
        nvrtc=0;
    end
    data3=cell(1,Nr);
    for l=1:Nl
        if numvalues(hm1)>max_no_values
            nn1=numvalues(hm1);
            nloops=ceil(nn1/max_no_values);
            nn=round(nn1/nloops);
            for ij=1:nloops
                if ij~=nloops % this if statement is because the n vertices/vxl may differ across ij values
                    for rs=1:Nr
                        data3{rs}=squeeze(data{rs}(1+nvrtc+(nn*(ij-1)):nn+nvrtc+(nn*(ij-1)),l,:));
                    end
                else
                    for rs=1:Nr
                        data3{rs}=squeeze(data{rs}(1+nvrtc+(nn*(nloops-1)):numvalues(hm1)+nvrtc,l,:));
                    end
                end
                sprintf('processing %i/%i of %s vertives in layer %i',ij,nloops,hmv{hm1},l)
                tic
                results2 = analyzePRF(stimulus,data3,1,struct('xvalmode',1, ...
                    'seedmode',-2,'wantglmdenoise',0));
                toc
                if ij==1
                    results3=results2;
                else
                    sz=size(results3.ang,1);
                    fnm=fieldnames(results2);
                    bad={'params' 'options' 'noisereg' 'hrf'};
                    for fnmi=1:size(fnm,1)
                        if ~ismember(fnm{fnmi},bad)  %cell2mat(strfind(bad,fnm{fnmi}))==0
                            eval(['results3.',fnm{fnmi},'(1+sz:sz+size(results2.ang,1),:)=results2.',fnm{fnmi},';']);
                        end
                    end
                    results3.options.vxs(:,1+sz:size(results2.ang,1)+sz)=results2.options.vxs;
                    results3.options.hrf=results2.options.hrf;
                    results3.params(:,:,1+sz:size(results2.ang,1)+sz)=results2.params;
                end
            end
            if size(results3.ang,1)~=numvalues(hm1)
                error('error - number of vertices in results structure doesnt match number of vertices in data structure')
            end
            eval([hmv{hm1},'_results_l',num2str(l),'=results3;'])
            if ~isdir(outputdir)
                mkdir(outputdir)
            end
            save([outputdir,'/',subjid,'_',hmv{hm1},'_',extnm,'_layer',num2str(l),'_results_PRF.mat'],...
                [hmv{hm1},'_results_l',num2str(l)],'-v7.3')
        else
            for rs=1:Nr
                data3{rs}=squeeze(data{rs}(1+nvrtc:numvalues(hm1)+nvrtc,l,:));
            end
            sprintf('processing %s layer %s',hmv{hm1},num2str(l))
            tic
            results3 = analyzePRF(stimulus,data3,1,struct('xvalmode',1, ...
                'seedmode',-2,'wantglmdenoise',0));
            toc
            eval([hmv{hm1},'_results_l',num2str(l),'=results3;'])
            if ~isdir(outputdir)
                mkdir(outputdir)
            end
            save([outputdir,'/',subjid,'_',hmv{hm1},'_',extnm,'_layer',num2str(l),'_results_PRF.mat'],...
                [hmv{hm1},'_results_l',num2str(l)],'-v7.3')
        end
        if flagmgz==1
            outputdirmgz=[outputdir,'/','mgz'];
            if ~exist(outputdirmgz,'dir')
                mkdir(outputdirmgz)
            end
            for fnmi=foi
                fnm=fieldnames(results3);
                tmp3=eval(['results3.',fnm{fnmi}]);
                cvnwritemgz(subjid,[hmv{hm1},'_',extnm,'_layer',num2str(l),...
                    '_results_PRF_',fnm{fnmi}],tmp3,hmv{hm1},outputdirmgz);
            end
        end
    end
end
