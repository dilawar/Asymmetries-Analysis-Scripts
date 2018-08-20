clearvars
clc

%% This script will load a file with two channel gap free data Ch#1 Patch trace
%  and Ch#2 Polygon trace, and use the grid coordinates file (sequentially or
%  randomly ordered) and generate a matrix of tracelets for all the polygon
%  squares in order.

acqRate = 20;
pre = 25; 
post = 75;
points = acqRate*(pre+post)+1; %Number of datapoints

%% Load files

[FileName,PathName]=uigetfile('*.mat;*.txt','Pick the Data File'); %Opens a file selection box
TraceFile = strcat(PathName,FileName);
cd(PathName) %Change the working directory to the path
load(FileName) %Load the file
ExptID = strsplit(FileName,'.'); %Extract the filename ignoring the extension
ExptID = ExptID(1); ExptID = ExptID{1};

% To import the external grid coordinates

%Get the Coordinates file using GUI window
[coordFileName, coordFilePathName]=uigetfile('*.txt','Select the file with Grid Order');

%Open and scan it for the fourth column as the coordinates data is always
%in the fourth column. In textscan, %u = unsigned integer format, an
%asterisk in %*u means that that column is to be skipped

fid = fopen(coordFileName);
coord = textscan(fid,'%*u%*u%*u%u');
fclose(fid);
coord = coord{1};

%Estimating grid size from the coordinates file
gridSize = sqrt(length(coord));

%% Create Traces and Separate out Triggered Responses

% All data files are parsed and therefore have two variables
% 1)PatchTrace
% 2)PolygonTrace

%Create TimeTrace
TimeTrace = linspace(0,length(PatchTrace)/(1000*acqRate),length(PatchTrace));

%Find out the maximum value of polygon TTL received to use that
% to find locations of the peaks
maxPolygon = max(PolygonTrace);

% Locations of the TTLs in channel 2 i.e. Polygon
% In the line below the original output of the function was to [peaks, locs]
% MATLAB suggested I use '~' instead of peaks because I was not using the
% variable peaks anywhere. Using a tilde instead of a variable ignores that
% particular function output and saves computing

[~, locs] = findpeaks(PolygonTrace,'MinPeakHeight',0.95*maxPolygon,'MinPeakDistance',18000,'Npeaks',gridSize^2);

% Create a matrix in which each row corresponds to a section of 
% patch trace around the stimulus
PatchTracelets=zeros(length(locs),points);

%Fill in the matrix using locations of TTL peaks
for i=1:length(locs)
    PatchTracelets(i,:)=PatchTrace((locs(i)-pre*acqRate):(locs(i)+post*acqRate));
    % Baseline subtraction
    % A mean value is calculated between datapoints 100 and 400
    % this mean is then subtracted from the entire traceline
    % thus shifting the trace to zero.
    baseline = mean(PatchTracelets(i,100:400));
    PatchTracelets(i,:) = PatchTracelets(i,:)-baseline;
end

%% Reshuffeling the tracelets according to the external order

orderedTracelets = zeros(size(PatchTracelets));
for i=1:length(locs)
    % The remapping of squares is done here using a variable 'j' which maps
    % the index i onto the correct coordinate of the square from the coord
    % data
    j = coord(i);
    orderedTracelets(j,:)= PatchTracelets(i,:);
end

%% Save the data

clear ans baseline coord* fid FileName i j peaks maxPolygon
clear Poly* T*

mkdir(ExptID)
ParsedFilePath = strcat(PathName,ExptID,'\');
cd(ParsedFilePath) %Change the working directory to the path
ParsedFile = strcat(ParsedFilePath,ExptID,'_Parsed_Tracelets_',num2str(gridSize),'.mat');
save(ParsedFile)


