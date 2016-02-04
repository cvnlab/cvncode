function cvnupsampledata_beta(datafiles,newtr,expectedlength,outputdir)
%cvnupsampledata(datafiles,newtr,expectedlength,outputdir)
%
%Upsamples data to newtr and if necessary truncates upsampled data to match
%expectedlength. The function will create a .mat file under the original 
%filename with the added extension "_<newtr>sec". The newly created .mat 
%file will contain the following variables:
%data --> upsampled data (int16 precision)
%numrh --> number of right hemisphere vertices
%numlh --> number of left hemisphere vertices
%newtr -> new TR
%
%this function assumes data to be a timepoints x layers x numberofvertices
%matrix
%
%%<datafiles> cell array containing the path to and the data filename. It
%%can be a wildcard
%
%<newtr> scalar indicating the new TR the data will be upsampled to
%
%<expectedlength> scalar indicating the expected length (in TR) of the
%upsampled timeseries (optional - if not provided or empty expectedlength 
%will be set to ceil(orignal_data_number_of_volumes * orignal_data_TR/newtr) 
%
%<outputdir> string indicating the path to where the upsampled data will be
%saved. Optional - if not provided data will be saved in the folder where
%the original data are stored

% load in data
if ischar(datafiles)
    datafiles={datafiles};
end
datafiles=matchfiles(datafiles);
Nr=length(datafiles);
%%%%%%%%%%%% THIS IS THE NEW BIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('expectedlength','var') || isempty(expectedlength)
    tmpdata=matfile(datafiles{1});
    expectedlength=ceil(size(tmpdata.data,1)*(tmpdata.tr/newtr));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load data
for r=1:Nr
    load(datafiles{r})
    % upsample data to match the stimulus resolution and save upsampled data
    tmp1=single(zeros(expectedlength,size(data,2),size(data,3)));% create new matrix that will contain the upsampled data
    for l=1:size(data,2) % layer loop
        sprintf('upsampling run %d layer %d ... please wait',r,l)
        tmp=single(squeeze(data(:,l,:)));
        tic
        tmptmp=tseriesinterp(tmp,tr,newtr,1); % upsampling time series using kendrick's tseriesinterp function
        toc
        tmp1(:,l,:)=tmptmp(1:expectedlength,:);
    end
    if size(tmp1,1)~=expectedlength
        error(['error the upsampled time series does not match the stimulus'...
            ' time resolutions'])
    end
    tr=newtr;
    idxnm=strfind(datafiles{r},'/');
    name=datafiles{r}(idxnm(end)+1:end-4);
    if ~exist('outputdir','var') || isempty(outputdir) %[[updated to add the isempty bit]]
        outputdir=datafiles{r}(1:idxnm(end));
    end
    data=int16(tmp1);
    save([outputdir,name,'_',num2str(newtr),'sec.mat'],'data','tr','numlh','numrh','-v7.3')
end
