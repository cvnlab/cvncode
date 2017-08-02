function Pnew = fast_fix_patch_kj(P,fullfaces)
% Make sure the patch does not have extra vertices.
% P = from fast_read_patch_kj
% fullfaces = Nx3 vertex indices from original full surface

M = false(max([fullfaces(:); P.ind(:)]),1);
M(P.ind) = true;

F = fullfaces(all(M(fullfaces),2),:);

ind = unique(reshape(F,[],1));
edgevert = unique(reshape(surfedge(F),[],1));

[~,ia] = intersect(P.ind,ind);

Pnew = struct('x',P.x(ia),'y',P.y(ia),'z',P.z(ia),...
    'ind',ind,'vno',ind,'edge',edgevert,'npts',numel(ind));
