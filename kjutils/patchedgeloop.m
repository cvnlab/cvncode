function newloop = patchedgeloop(faces,return_biggest)
% newloop = patchedgeloop(faces,[return_biggest=false])
%
% Inputs
%   faces: Fx3 vertex indices defining triangle mesh faces
%   return_biggest: true|false to only return longest loop found (default=false)
%
% Outputs
%   newloop: 1xN row vector of vertex indices defining a path around the
%       open edges of the patch. If more than one loop exists, newloop
%       concatenates them, separated by "nan".  (unless return_biggest=true)

%1. Find edges that only appear in a single face in faces
%2. Connect the vertices in order to form a loop

if(~exist('return_biggest','var') || isempty(return_biggest))
    return_biggest=false;
end

edges=[faces(:,[1 2]); faces(:,[1 3]); faces(:,[2 3])];
edges=sort(edges,2);
[a,b,c]=unique(edges,'rows');
cc=histc(c,1:numel(b));

loopedges=a(cc==1,:);

oldloop=loopedges;

o=loopedges(1);

c=1;
newloop=oldloop(:);
newloop(c)=o;

for i = 1:size(loopedges,1)
    r=find(any(oldloop==o,2));
    if(isempty(r))
        remain=oldloop(oldloop>0);
        if(isempty(remain))
            break;
        else
            c=c+1;
            newloop(c)=nan;
            o=remain(1);
            continue;
        end
    end

    r=r(1);
    m=oldloop(r,:);
    o=m(m~=o);
    oldloop(r,:)=0;
    
    c=c+1;
    newloop(c)=o;

end
newloop=newloop(1:c);

if(return_biggest)
    if(any(isnan(newloop)))
        loopstarts=[1; find(isnan(newloop))+1];
        loopends=[loopstarts(2:end)-2; numel(newloop)];
        loopsizes=loopends-loopstarts+1;
        [~,bigloopidx]=max(loopsizes);
        newloop=newloop(loopstarts(bigloopidx):loopends(bigloopidx));
    end
end