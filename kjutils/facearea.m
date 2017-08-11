function A = facearea(faces,vertices)
%A = facearea(faces,vertices)
%
%return surface area of each face in a triangle mesh

L = reshape(edgelengths(faces,vertices),[],3);
s = sum(L,2)/2;
A = sqrt(s.*prod(bsxfun(@minus,s,L),2));
