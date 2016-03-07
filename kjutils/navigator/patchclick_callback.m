function patchclick_callback(gcbo,eventdata,cbfun,varargin)
% patchclick_callback(gcbo,eventdata,cbfun,...)
%
% Set up a callback function for a patch object so that
%  when the patch is clicked, the index and coordinates of the
%  clicked vertex is sent to the callback input cbfun

curpoint = get(gca,'CurrentPoint');
q1 = curpoint(1,:);
q2 = curpoint(2,:);

d = q2-q1;
d = d/norm(d);

verts = get(gcbo,'Vertices');
norms = get(gcbo,'VertexNormals');
faces = get(gcbo,'Faces');

[intersect,indx,dist,u,v] = ray_intersect(faces,verts,q1,d,'b');

%find the closest face to the starting point
[dmin dindx] = min(dist);
closest_face_idx = indx(dindx(1));
closest_face_verts = verts(faces(closest_face_idx,:),:);

%find the closest of the face's 3 verts to the line
d = DistanceFromPointToLine(closest_face_verts, q1,q2);
[dmin dindx] = min(d);

vert_idx = faces(closest_face_idx,dindx);
closest_vert = verts(vert_idx,:);

cbfun(vert_idx,closest_vert,varargin{:});
