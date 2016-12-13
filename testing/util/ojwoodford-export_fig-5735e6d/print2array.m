%PRINT2ARRAY  Exports a figure to an image array
%
% Examples:
%   A = print2array
%   A = print2array(figure_handle)
%   A = print2array(figure_handle, resolution)
%   A = print2array(figure_handle, resolution, renderer)
%   [A bcol] = print2array(...)
%
% This function outputs a bitmap image of the given figure, at the desired
% resolution.
%
% If renderer is '-painters' then ghostcript needs to be installed. This
% can be downloaded from: http://www.ghostscript.com
%
% IN:
%   figure_handle - The handle of the figure to be exported. Default: gcf.
%   resolution - Resolution of the output, as a factor of screen
%                resolution. Default: 1.
%   renderer - string containing the renderer paramater to be passed to
%              print. Default: '-opengl'.
%
% OUT:
%   A - MxNx3 uint8 image of the figure.
%   bcol - 1x3 uint8 vector of the background color

% Copyright (C) Oliver Woodford 2008-2012

% 05/09/11: Set EraseModes to normal when using opengl or zbuffer
%           renderers. Thanks to Pawel Kocieniewski for reporting the
%           issue.
% 21/09/11: Bug fix: unit8 -> uint8! Thanks to Tobias Lamour for reporting
%           the issue.
% 14/11/11: Bug fix: stop using hardcopy(), as it interfered with figure
%           size and erasemode settings. Makes it a bit slower, but more
%           reliable. Thanks to Phil Trinh and Meelis Lootus for reporting
%           the issues.
% 09/12/11: Pass font path to ghostscript.
% 27/01/12: Bug fix affecting painters rendering tall figures. Thanks to
%           Ken Campbell for reporting it.
% 03/04/12: Bug fix to median input. Thanks to Andy Matthews for reporting
%           it.
% 26/10/12: Set PaperOrientation to portrait. Thanks to Michael Watts for
%           reporting the issue.

function [A, bcol] = print2array(fig, res, renderer)
% Generate default input arguments, if needed
if nargin < 2
    res = 1;
    if nargin < 1
        fig = gcf;
    end
end
% Warn if output is large
old_mode = get(fig, 'Units');
set(fig, 'Units', 'pixels');
px = get(fig, 'Position');
set(fig, 'Units', old_mode);
npx = prod(px(3:4)*res)/1e6;
if npx > 30
    % 30M pixels or larger!
    warning('MATLAB:LargeImage', 'print2array generating a %.1fM pixel image. This could be slow and might also cause memory problems.', npx);
end
% Retrieve the background colour
bcol = get(fig, 'Color');
% Set the resolution parameter
res_str = ['-r' num2str(ceil(get(0, 'ScreenPixelsPerInch')*res))];
% Generate temporary file name
tmp_nam = [tempname '.tif'];
if nargin > 2 && strcmp(renderer, '-painters')
    % Print to eps file
    tmp_eps = [tempname '.eps'];
    print2eps(tmp_eps, fig, renderer, '-loose');
    try
        % Initialize the command to export to tiff using ghostscript
        cmd_str = ['-dEPSCrop -q -dNOPAUSE -dBATCH ' res_str ' -sDEVICE=tiff24nc'];
        % Set the font path
        fp = font_path();
        if ~isempty(fp)
            cmd_str = [cmd_str ' -sFONTPATH="' fp '"'];
        end
        % Add the filenames
        cmd_str = [cmd_str ' -sOutputFile="' tmp_nam '" "' tmp_eps '"'];
        % Execute the ghostscript command
        ghostscript(cmd_str);
    catch me
        % Delete the intermediate file
        delete(tmp_eps);
        rethrow(me);
    end
    % Delete the intermediate file
    delete(tmp_eps);
    % Read in the generated bitmap
    A = imread(tmp_nam);
    % Delete the temporary bitmap file
    delete(tmp_nam);
    % Set border pixels to the correct colour
    if isequal(bcol, 'none')
        bcol = [];
    elseif isequal(bcol, [1 1 1])
        bcol = uint8([255 255 255]);
    else
        for l = 1:size(A, 2)
            if ~all(reshape(A(:,l,:) == 255, [], 1))
                break;
            end
        end
        for r = size(A, 2):-1:l
            if ~all(reshape(A(:,r,:) == 255, [], 1))
                break;
            end
        end
        for t = 1:size(A, 1)
            if ~all(reshape(A(t,:,:) == 255, [], 1))
                break;
            end
        end
        for b = size(A, 1):-1:t
            if ~all(reshape(A(b,:,:) == 255, [], 1))
                break;
            end
        end
        bcol = uint8(median(single([reshape(A(:,[l r],:), [], size(A, 3)); reshape(A([t b],:,:), [], size(A, 3))]), 1));
        for c = 1:size(A, 3)
            A(:,[1:l-1, r+1:end],c) = bcol(c);
            A([1:t-1, b+1:end],:,c) = bcol(c);
        end
    end
else
    if nargin < 3
        renderer = '-opengl';
    end
    err = false;
    % Set paper size
    old_pos_mode = get(fig, 'PaperPositionMode');
    old_orientation = get(fig, 'PaperOrientation');
    set(fig, 'PaperPositionMode', 'auto', 'PaperOrientation', 'portrait');
    try
        % Print to tiff file
        print(fig, renderer, res_str, '-dtiff', tmp_nam);
        % Read in the printed file
        A = imread(tmp_nam);
        % Delete the temporary file
        delete(tmp_nam);
    catch ex
        err = true;
    end
    % Reset paper size
    set(fig, 'PaperPositionMode', old_pos_mode, 'PaperOrientation', old_orientation);
    % Throw any error that occurred
    if err
        rethrow(ex);
    end
    % Set the background color
    if isequal(bcol, 'none')
        bcol = [];
    else
        bcol = bcol * 255;
        if isequal(bcol, round(bcol))
            bcol = uint8(bcol);
        else
            bcol = squeeze(A(1,1,:));
        end
    end
end
% Check the output size is correct
if isequal(res, round(res))
    px = [px([4 3])*res 3];
    if ~isequal(size(A), px)
        % Correct the output size
        A = A(1:min(end,px(1)),1:min(end,px(2)),:);
    end
end
return

% Function to return (and create, where necessary) the font path
function fp = font_path()
fp = user_string('gs_font_path');
if ~isempty(fp)
    return
end
% Create the path
% Start with the default path
fp = getenv('GS_FONTPATH');
% Add on the typical directories for a given OS
if ispc
    if ~isempty(fp)
        fp = [fp ';'];
    end
    fp = [fp getenv('WINDIR') filesep 'Fonts'];
else
    if ~isempty(fp)
        fp = [fp ':'];
    end
    fp = [fp '/usr/share/fonts:/usr/local/share/fonts:/usr/share/fonts/X11:/usr/local/share/fonts/X11:/usr/share/fonts/truetype:/usr/local/share/fonts/truetype'];
end
user_string('gs_font_path', fp);
return
