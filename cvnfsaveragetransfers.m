function cvnfsaveragetransfers(subjectid)

% function cvnfsaveragetransfers(subjectid)
%
% <subjectid> is like 'cvn7002'
%
% Create subject<->fsaverage transfers.
% The subject can be fsaverage!

%% %%%%% Calculate some stuff

fsdir = sprintf('%s/%s/',cvnpath('freesurfer'),subjectid);

%% %%%%% Create subject fsaverage transfers

hemis={'lh','rh'};
surfsuffixes={'orig','DENSE'};

for ss = 1:numel(surfsuffixes)
    surfsuffix=surfsuffixes{ss};
    
    if(isequal(surfsuffix,'orig'))
        fsavgsuffix='';
    else
        fsavgsuffix=surfsuffix;
    end
    
    % e.g., if lh.whiteDENSE does not exist (e.g. because we did not do dense processing), just skip this case
    if ~exist(sprintf('%s/surf/lh.white%s',fsdir,fsavgsuffix),'file')
      continue;
    end
    
    for h = 1:numel(hemis)
        hemi=hemis{h};
        
        numvals=cvnreadsurface(subjectid,hemi,'sphere',surfsuffix,'justcount',true);
        
        %forward transform
        validix=cvntransfertosubject(subjectid,'fsaverage',(1:numvals)',hemi,'nearest',surfsuffix,surfsuffix);
        xferfile=sprintf('%s/surf/%s.%s_to_fsaverage%s.mat',fsdir,hemi,surfsuffix,fsavgsuffix);
        save(xferfile,'validix');
        
        %backward transform
        numvals_fsvals=numel(validix);
        validix=cvntransfertosubject('fsaverage',subjectid,(1:numvals_fsvals)',hemi,'nearest',surfsuffix,surfsuffix);
        xferfile=sprintf('%s/surf/%s.fsaverage%s_to_%s.mat',fsdir,hemi,fsavgsuffix,surfsuffix);
        save(xferfile,'validix');
        
    end
end
