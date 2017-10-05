function [ d ] = matvoldir
%MATVOLDIR get the fullpath directory of matvol

d = [ fileparts(mfilename('fullpath')) filesep];

end

