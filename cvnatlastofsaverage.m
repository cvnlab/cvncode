function cvnatlastofsaverage(outtypes,rois)

% function cvnatlastofsaverage(outtypes,rois)
%
% <outtypes> is like {'orig','DENSE','DENSETRUNCpt'}
% <rois> is a cell vector of ROI names
%
% Map ROIs onto fsaverage, fsaverageDENSE, fsaverageDENSETRUNCpt.
% Note that this is only for the fsaverage subject!

subjectid='fsaverage';
outdir=sprintf('%s/%s/label',cvnpath('freesurfer'),subjectid);
hemis={'lh','rh'};
fmapdir = '/home/stone/software/freesurferspecialfiles/fsaveragemaps/';

for zz=1:length(rois)
  for o = 1:numel(outtypes)
      outtype=outtypes{o};
      if(isequal(outtype,'orig'))
          outtype_file='';
      else
          outtype_file=outtype;
      end
      for h = 1:numel(hemis)
          hemi=hemis{h};
          val = load_mgh(sprintf('%s/%s.%s.mgz',fmapdir,hemis{h},rois{zz}));
          assert(all(isfinite(val(:))));
          val2=cvnlookupvertex('fsaverage',hemi,'orig',outtype,val(:));
          cvnwritemgz(subjectid,rois{zz},val2,[hemi outtype_file],outdir);
      end
  end
end
