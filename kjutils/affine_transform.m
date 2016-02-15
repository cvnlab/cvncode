function output = affine_transform(M, input)
%output = affine_transform(M, input)
% M: 4x4
% input: Nx3
% output: Nx3

  %output = M * [input.'; ones(1, size(input, 1))];
  %output = output(1:3,:)';
  
  %2x faster:
  input(:,4)=1;
  output = input*(M(1:3,:).');
end
