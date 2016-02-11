function [center,radius,residuals] = spherefit(x,y,z)
%SPHEREFIT find least squares sphere
%
% Fit a sphere to a set of xyz data points
% [center,radius,residuals] = shperefit(X)
% [center,radius,residuals] = spherefit(x,y,z);
% Input
% x,y,z Cartesian data, n x 3 matrix or three vectors (n x 1 or 1 x n)
% Output
% center least squares sphere center coordinates, == [xc yc zc]
% radius radius of curvature
% residuals residuals in the radial direction
%
% Fit the equation of a sphere in Cartesian coordinates to a set of xyz
% data points by solving the overdetermined system of normal equations,
% ie, x^2 + y^2 + z^2 + a*x + b*y + c*z + d = 0
% The least squares sphere has radius R = sqrt((a^2+b^2+c^2)/4-d) and
% center coordinates (x,y,z) = (-a/2,-b/2,-c/2)

error(nargchk(1,3,nargin)); % check input arguments
if nargin == 1 % n x 3 matrix
   if size(x,2) ~= 3
      error ('input data must have three columns')
   else
      z = x(:,3); % save columns as x,y,z vectors
      y = x(:,2);
      x = x(:,1);
   end
elseif nargin == 3 % three x,y,z vectors
   x = x(:); % force into columns
   y = y(:);
   z = z(:);
   if ~isequal(length(x),length(y),length(z)) % same length ?
      error('input vectors must be same length');
   end
else % must have one or three inputs
   error('invalid input, n x 3 matrix or 3 n x 1 vectors expected');
end

% need four or more data points
if length(x) < 4
   error('must have at least four points to fit a unique sphere');
end

% solve linear system of normal equations
A = [x y z ones(size(x))];
b = -(x.^2 + y.^2 + z.^2);
a = A \ b;

% return center coordinates and sphere radius
center = -a(1:3)./2;
radius = sqrt(sum(center.^2)-a(4));

% calculate residuals
if nargout > 2
   residuals = radius - sqrt(sum(bsxfun(@minus,[x y z],center.').^2,2));
end