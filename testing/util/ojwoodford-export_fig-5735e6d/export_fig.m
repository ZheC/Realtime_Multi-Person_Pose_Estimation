%EXPORT_FIG  Exports figures suitable for publication
%
% Examples:
%   im = export_fig
%   [im alpha] = export_fig
%   export_fig filename
%   export_fig filename -format1 -format2
%   export_fig ... -nocrop
%   export_fig ... -transparent
%   export_fig ... -native
%   export_fig ... -m<val>
%   export_fig ... -r<val>
%   export_fig ... -a<val>
%   export_fig ... -q<val>
%   export_fig ... -<renderer>
%   export_fig ... -<colorspace>
%   export_fig ... -append
%   export_fig ... -bookmark
%   export_fig(..., handle)
%
% This function saves a figure or single axes to one or more vector and/or
% bitmap file formats, and/or outputs a rasterized version to the
% workspace, with the following properties:
%   - Figure/axes reproduced as it appears on screen
%   - Cropped borders (optional)
%   - Embedded fonts (vector formats)
%   - Improved line and grid line styles
%   - Anti-aliased graphics (bitmap formats)
%   - Render images at native resolution (optional for bitmap formats)
%   - Transparent background supported (pdf, eps, png)
%   - Semi-transparent patch objects supported (png only)
%   - RGB, CMYK or grayscale output (CMYK only with pdf, eps, tiff)
%   - Variable image compression, including lossless (pdf, eps, jpg)
%   - Optionally append to file (pdf, tiff)
%   - Vector formats: pdf, eps
%   - Bitmap formats: png, tiff, jpg, bmp, export to workspace 
%   
% This function is especially suited to exporting figures for use in
% publications and presentations, because of the high quality and
% portability of media produced.
%
% Note that the background color and figure dimensions are reproduced
% (the latter approximately, and ignoring cropping & magnification) in the
% output file. For transparent background (and semi-transparent patch
% objects), use the -transparent option or set the figure 'Color' property
% to 'none'. To make axes transparent set the axes 'Color' property to
% 'none'. Pdf, eps and png are the only file formats to support a
% transparent background, whilst the png format alone supports transparency
% of patch objects.
%
% The choice of renderer (opengl, zbuffer or painters) has a large impact
% on the quality of output. Whilst the default value (opengl for bitmaps,
% painters for vector formats) generally gives good results, if you aren't
% satisfied then try another renderer.  Notes: 1) For vector formats (eps,
% pdf), only painters generates vector graphics. 2) For bitmaps, only
% opengl can render transparent patch objects correctly. 3) For bitmaps,
% only painters will correctly scale line dash and dot lengths when
% magnifying or anti-aliasing. 4) Fonts may be substitued with Courier when
% using painters.
%
% When exporting to vector format (pdf & eps) and bitmap format using the
% painters renderer, this function requires that ghostscript is installed
% on your system. You can download this from:
%   http://www.ghostscript.com
% When exporting to eps it additionally requires pdftops, from the Xpdf
% suite of functions. You can download this from:
%   http://www.foolabs.com/xpdf
%
%IN:
%   filename - string containing the name (optionally including full or
%              relative path) of the file the figure is to be saved as. If
%              a path is not specified, the figure is saved in the current
%              directory. If no name and no output arguments are specified,
%              the default name, 'export_fig_out', is used. If neither a
%              file extension nor a format are specified, a ".png" is added
%              and the figure saved in that format.
%   -format1, -format2, etc. - strings containing the extensions of the
%                              file formats the figure is to be saved as.
%                              Valid options are: '-pdf', '-eps', '-png',
%                              '-tif', '-jpg' and '-bmp'. All combinations
%                              of formats are valid.
%   -nocrop - option indicating that the borders of the output are not to
%             be cropped.
%   -transparent - option indicating that the figure background is to be
%                  made transparent (png, pdf and eps output only).
%   -m<val> - option where val indicates the factor to magnify the
%             on-screen figure pixel dimensions by when generating bitmap
%             outputs. Default: '-m1'.
%   -r<val> - option val indicates the resolution (in pixels per inch) to
%             export bitmap and vector outputs at, keeping the dimensions
%             of the on-screen figure. Default: '-r864' (for vector output
%             only). Note that the -m option overides the -r option for
%             bitmap outputs only.
%   -native - option indicating that the output resolution (when outputting
%             a bitmap format) should be such that the vertical resolution
%             of the first suitable image found in the figure is at the
%             native resolution of that image. To specify a particular
%             image to use, give it the tag 'export_fig_native'. Notes:
%             This overrides any value set with the -m and -r options. It
%             also assumes that the image is displayed front-to-parallel
%             with the screen. The output resolution is approximate and
%             should not be relied upon. Anti-aliasing can have adverse
%             effects on image quality (disable with the -a1 option).
%   -a1, -a2, -a3, -a4 - option indicating the amount of anti-aliasing to
%                        use for bitmap outputs. '-a1' means no anti-
%                        aliasing; '-a4' is the maximum amount (default).
%   -<renderer> - option to force a particular renderer (painters, opengl
%                 or zbuffer) to be used over the default: opengl for
%                 bitmaps; painters for vector formats.
%   -<colorspace> - option indicating which colorspace color figures should
%                   be saved in: RGB (default), CMYK or gray. CMYK is only
%                   supported in pdf, eps and tiff output.
%   -q<val> - option to vary bitmap image quality (in pdf, eps and jpg
%             files only).  Larger val, in the range 0-100, gives higher
%             quality/lower compression. val > 100 gives lossless
%             compression. Default: '-q95' for jpg, ghostscript prepress
%             default for pdf & eps. Note: lossless compression can
%             sometimes give a smaller file size than the default lossy
%             compression, depending on the type of images.
%   -append - option indicating that if the file (pdfs only) already
%             exists, the figure is to be appended as a new page, instead
%             of being overwritten (default).
%   -bookmark - option to indicate that a bookmark with the name of the
%               figure is to be created in the output file (pdf only).
%   handle - The handle of the figure, axes or uipanels (can be an array of
%            handles, but the objects must be in the same figure) to be
%            saved. Default: gcf.
%
%OUT:
%   im - MxNxC uint8 image array of the figure.
%   alpha - MxN single array of alphamatte values in range [0,1], for the
%           case when the background is transparent.
%
%   Some helpful examples and tips can be found at:
%      http://sites.google.com/site/oliverwoodford/software/export_fig
%
%   See also PRINT, SAVEAS.

% Copyright (C) Oliver Woodford 2008-2014

% The idea of using ghostscript is inspired by Peder Axensten's SAVEFIG
% (fex id: 10889) which is itself inspired by EPS2PDF (fex id: 5782).
% The idea for using pdftops came from the MATLAB newsgroup (id: 168171).
% The idea of editing the EPS file to change line styles comes from Jiro
% Doke's FIXPSLINESTYLE (fex id: 17928).
% The idea of changing dash length with line width came from comments on
% fex id: 5743, but the implementation is mine :)
% The idea of anti-aliasing bitmaps came from Anders Brun's MYAA (fex id:
% 20979).
% The idea of appending figures in pdfs came from Matt C in comments on the
% FEX (id: 23629)

% Thanks to Roland Martin for pointing out the colour MATLAB
% bug/feature with colorbar axes and transparent backgrounds.
% Thanks also to Andrew Matthews for describing a bug to do with the figure
% size changing in -nodisplay mode. I couldn't reproduce it, but included a
% fix anyway.
% Thanks to Tammy Threadgill for reporting a bug where an axes is not
% isolated from gui objects.

% 23/02/12: Ensure that axes limits don't change during printing
% 14/03/12: Fix bug in fixing the axes limits (thanks to Tobias Lamour for
%           reporting it).
% 02/05/12: Incorporate patch of Petr Nechaev (many thanks), enabling
%           bookmarking of figures in pdf files.
% 09/05/12: Incorporate patch of Arcelia Arrieta (many thanks), to keep
%           tick marks fixed.
% 12/12/12: Add support for isolating uipanels. Thanks to michael for
%           suggesting it.
% 25/09/13: Add support for changing resolution in vector formats. Thanks
%           to Jan Jaap Meijer for suggesting it.
% 07/05/14: Add support for '~' at start of path. Thanks to Sally Warner
%           for suggesting it.

function [im, alpha] = export_fig(varargin)
% Make sure the figure is rendered correctly _now_ so that properties like
% axes limits are up-to-date.
drawnow;
% Parse the input arguments
[fig, options] = parse_args(nargout, varargin{:});
% Isolate the subplot, if it is one
cls = all(ismember(get(fig, 'Type'), {'axes', 'uipanel'}));
if cls
    % Given handles of one or more axes, so isolate them from the rest
    fig = isolate_axes(fig);
else
    % Check we have a figure
    if ~isequal(get(fig, 'Type'), 'figure');
        error('Handle must be that of a figure, axes or uipanel');
    end
    % Get the old InvertHardcopy mode
    old_mode = get(fig, 'InvertHardcopy');
end
% Hack the font units where necessary (due to a font rendering bug in
% print?). This may not work perfectly in all cases. Also it can change the
% figure layout if reverted, so use a copy.
magnify = options.magnify * options.aa_factor;
if isbitmap(options) && magnify ~= 1
    fontu = findobj(fig, 'FontUnits', 'normalized');
    if ~isempty(fontu)
        % Some normalized font units found
        if ~cls
            fig = copyfig(fig);
            set(fig, 'Visible', 'off');
            fontu = findobj(fig, 'FontUnits', 'normalized');
            cls = true;
        end
        set(fontu, 'FontUnits', 'points');
    end
end
% MATLAB "feature": axes limits and tick marks can change when printing
Hlims = findall(fig, 'Type', 'axes');
if ~cls
    % Record the old axes limit and tick modes
    Xlims = make_cell(get(Hlims, 'XLimMode'));
    Ylims = make_cell(get(Hlims, 'YLimMode'));
    Zlims = make_cell(get(Hlims, 'ZLimMode'));
    Xtick = make_cell(get(Hlims, 'XTickMode'));
    Ytick = make_cell(get(Hlims, 'YTickMode'));
    Ztick = make_cell(get(Hlims, 'ZTickMode'));
end
% Set all axes limit and tick modes to manual, so the limits and ticks can't change
set(Hlims, 'XLimMode', 'manual', 'YLimMode', 'manual', 'ZLimMode', 'manual', 'XTickMode', 'manual', 'YTickMode', 'manual', 'ZTickMode', 'manual');
% Set to print exactly what is there
set(fig, 'InvertHardcopy', 'off');
% Set the renderer
switch options.renderer
    case 1
        renderer = '-opengl';
    case 2
        renderer = '-zbuffer';
    case 3
        renderer = '-painters';
    otherwise
        renderer = '-opengl'; % Default for bitmaps
end
% Do the bitmap formats first
if isbitmap(options)
    % Get the background colour
    if options.transparent && (options.png || options.alpha)
        % Get out an alpha channel
        % MATLAB "feature": black colorbar axes can change to white and vice versa!
        hCB = findobj(fig, 'Type', 'axes', 'Tag', 'Colorbar');
        if isempty(hCB)
            yCol = [];
            xCol = [];
        else
            yCol = get(hCB, 'YColor');
            xCol = get(hCB, 'XColor');
            if iscell(yCol)
                yCol = cell2mat(yCol);
                xCol = cell2mat(xCol);
            end
            yCol = sum(yCol, 2);
            xCol = sum(xCol, 2);
        end
        % MATLAB "feature": apparently figure size can change when changing
        % colour in -nodisplay mode
        pos = get(fig, 'Position');
        % Set the background colour to black, and set size in case it was
        % changed internally
        tcol = get(fig, 'Color');
        set(fig, 'Color', 'k', 'Position', pos);
        % Correct the colorbar axes colours
        set(hCB(yCol==0), 'YColor', [0 0 0]);
        set(hCB(xCol==0), 'XColor', [0 0 0]);
        % Print large version to array
        B = print2array(fig, magnify, renderer);
        % Downscale the image
        B = downsize(single(B), options.aa_factor);
        % Set background to white (and set size)
        set(fig, 'Color', 'w', 'Position', pos);
        % Correct the colorbar axes colours
        set(hCB(yCol==3), 'YColor', [1 1 1]);
        set(hCB(xCol==3), 'XColor', [1 1 1]);
        % Print large version to array
        A = print2array(fig, magnify, renderer);
        % Downscale the image
        A = downsize(single(A), options.aa_factor);
        % Set the background colour (and size) back to normal
        set(fig, 'Color', tcol, 'Position', pos);
        % Compute the alpha map
        alpha = round(sum(B - A, 3)) / (255 * 3) + 1;
        A = alpha;
        A(A==0) = 1;
        A = B ./ A(:,:,[1 1 1]);
        clear B
        % Convert to greyscale
        if options.colourspace == 2
            A = rgb2grey(A);
        end
        A = uint8(A);
        % Crop the background
        if options.crop
            [alpha, v] = crop_background(alpha, 0);
            A = A(v(1):v(2),v(3):v(4),:);
        end
        if options.png
            % Compute the resolution
            res = options.magnify * get(0, 'ScreenPixelsPerInch') / 25.4e-3;
            % Save the png
            imwrite(A, [options.name '.png'], 'Alpha', double(alpha), 'ResolutionUnit', 'meter', 'XResolution', res, 'YResolution', res);
            % Clear the png bit
            options.png = false;
        end
        % Return only one channel for greyscale
        if isbitmap(options)
            A = check_greyscale(A);
        end
        if options.alpha
            % Store the image
            im = A;
            % Clear the alpha bit
            options.alpha = false;
        end
        % Get the non-alpha image
        if isbitmap(options)
            alph = alpha(:,:,ones(1, size(A, 3)));
            A = uint8(single(A) .* alph + 255 * (1 - alph));
            clear alph
        end
        if options.im
            % Store the new image
            im = A;
        end
    else
        % Print large version to array
        if options.transparent
            % MATLAB "feature": apparently figure size can change when changing
            % colour in -nodisplay mode
            pos = get(fig, 'Position');
            tcol = get(fig, 'Color');
            set(fig, 'Color', 'w', 'Position', pos);
            A = print2array(fig, magnify, renderer);
            set(fig, 'Color', tcol, 'Position', pos);
            tcol = 255;
        else
            [A, tcol] = print2array(fig, magnify, renderer);
        end
        % Crop the background
        if options.crop
            A = crop_background(A, tcol);
        end
        % Downscale the image
        A = downsize(A, options.aa_factor);
        if options.colourspace == 2
            % Convert to greyscale
            A = rgb2grey(A);
        else
            % Return only one channel for greyscale
            A = check_greyscale(A);
        end
        % Outputs
        if options.im
            im = A;
        end
        if options.alpha
            im = A;
            alpha = zeros(size(A, 1), size(A, 2), 'single');
        end
    end
    % Save the images
    if options.png
        res = options.magnify * get(0, 'ScreenPixelsPerInch') / 25.4e-3;
        imwrite(A, [options.name '.png'], 'ResolutionUnit', 'meter', 'XResolution', res, 'YResolution', res);
    end
    if options.bmp
        imwrite(A, [options.name '.bmp']);
    end
    % Save jpeg with given quality
    if options.jpg
        quality = options.quality;
        if isempty(quality)
            quality = 95;
        end
        if quality > 100
            imwrite(A, [options.name '.jpg'], 'Mode', 'lossless');
        else
            imwrite(A, [options.name '.jpg'], 'Quality', quality);
        end
    end
    % Save tif images in cmyk if wanted (and possible)
    if options.tif
        if options.colourspace == 1 && size(A, 3) == 3
            A = double(255 - A);
            K = min(A, [], 3);
            K_ = 255 ./ max(255 - K, 1);
            C = (A(:,:,1) - K) .* K_;
            M = (A(:,:,2) - K) .* K_;
            Y = (A(:,:,3) - K) .* K_;
            A = uint8(cat(3, C, M, Y, K));
            clear C M Y K K_
        end
        append_mode = {'overwrite', 'append'};
        imwrite(A, [options.name '.tif'], 'Resolution', options.magnify*get(0, 'ScreenPixelsPerInch'), 'WriteMode', append_mode{options.append+1});
    end
end
% Now do the vector formats
if isvector(options)
    % Set the default renderer to painters
    if ~options.renderer
        renderer = '-painters';
    end
    % Generate some filenames
    tmp_nam = [tempname '.eps'];
    if options.pdf
        pdf_nam = [options.name '.pdf'];
    else
        pdf_nam = [tempname '.pdf'];
    end
    % Generate the options for print
    p2eArgs = {renderer, sprintf('-r%d', options.resolution)};
    if options.colourspace == 1
        p2eArgs = [p2eArgs {'-cmyk'}];
    end
    if ~options.crop
        p2eArgs = [p2eArgs {'-loose'}];
    end
    try
        % Generate an eps
        print2eps(tmp_nam, fig, p2eArgs{:});
        % Remove the background, if desired
        if options.transparent && ~isequal(get(fig, 'Color'), 'none')
            eps_remove_background(tmp_nam, 1 + using_hg2(fig));
        end
        % Add a bookmark to the PDF if desired
        if options.bookmark
            fig_nam = get(fig, 'Name');
            if isempty(fig_nam)
                warning('export_fig:EmptyBookmark', 'Bookmark requested for figure with no name. Bookmark will be empty.');
            end
            add_bookmark(tmp_nam, fig_nam);
        end
        % Generate a pdf
        eps2pdf(tmp_nam, pdf_nam, 1, options.append, options.colourspace==2, options.quality);
    catch ex
        % Delete the eps
        delete(tmp_nam);
        rethrow(ex);
    end
    % Delete the eps
    delete(tmp_nam);
    if options.eps
        try
            % Generate an eps from the pdf
            pdf2eps(pdf_nam, [options.name '.eps']);
        catch ex
            if ~options.pdf
                % Delete the pdf
                delete(pdf_nam);
            end
            rethrow(ex);
        end
        if ~options.pdf
            % Delete the pdf
            delete(pdf_nam);
        end
    end
end
if cls
    % Close the created figure
    close(fig);
else
    % Reset the hardcopy mode
    set(fig, 'InvertHardcopy', old_mode);
    % Reset the axes limit and tick modes
    for a = 1:numel(Hlims)
        set(Hlims(a), 'XLimMode', Xlims{a}, 'YLimMode', Ylims{a}, 'ZLimMode', Zlims{a}, 'XTickMode', Xtick{a}, 'YTickMode', Ytick{a}, 'ZTickMode', Ztick{a});
    end
end
return

function [fig, options] = parse_args(nout, varargin)
% Parse the input arguments
% Set the defaults
fig = get(0, 'CurrentFigure');
options = struct('name', 'export_fig_out', ...
                 'crop', true, ...
                 'transparent', false, ...
                 'renderer', 0, ... % 0: default, 1: OpenGL, 2: ZBuffer, 3: Painters
                 'pdf', false, ...
                 'eps', false, ...
                 'png', false, ...
                 'tif', false, ...
                 'jpg', false, ...
                 'bmp', false, ...
                 'colourspace', 0, ... % 0: RGB/gray, 1: CMYK, 2: gray
                 'append', false, ...
                 'im', nout == 1, ...
                 'alpha', nout == 2, ...
                 'aa_factor', 0, ...
                 'magnify', [], ...
                 'resolution', [], ...
                 'bookmark', false, ...
                 'quality', []);
native = false; % Set resolution to native of an image

% Go through the other arguments
for a = 1:nargin-1
    if all(ishandle(varargin{a}))
        fig = varargin{a};
    elseif ischar(varargin{a}) && ~isempty(varargin{a})
        if varargin{a}(1) == '-'
            switch lower(varargin{a}(2:end))
                case 'nocrop'
                    options.crop = false;
                case {'trans', 'transparent'}
                    options.transparent = true;
                case 'opengl'
                    options.renderer = 1;
                case 'zbuffer'
                    options.renderer = 2;
                case 'painters'
                    options.renderer = 3;
                case 'pdf'
                    options.pdf = true;
                case 'eps'
                    options.eps = true;
                case 'png'
                    options.png = true;
                case {'tif', 'tiff'}
                    options.tif = true;
                case {'jpg', 'jpeg'}
                    options.jpg = true;
                case 'bmp'
                    options.bmp = true;
                case 'rgb'
                    options.colourspace = 0;
                case 'cmyk'
                    options.colourspace = 1;
                case {'gray', 'grey'}
                    options.colourspace = 2;
                case {'a1', 'a2', 'a3', 'a4'}
                    options.aa_factor = str2double(varargin{a}(3));
                case 'append'
                    options.append = true;
                case 'bookmark'
                    options.bookmark = true;
                case 'native'
                    native = true;
                otherwise
                    val = str2double(regexp(varargin{a}, '(?<=-(m|M|r|R|q|Q))(\d*\.)?\d+(e-?\d+)?', 'match'));
                    if ~isscalar(val)
                        error('option %s not recognised', varargin{a});
                    end
                    switch lower(varargin{a}(2))
                        case 'm'
                            options.magnify = val;
                        case 'r'
                            options.resolution = val;
                        case 'q'
                            options.quality = max(val, 0);
                    end
            end
        else
            [p, options.name, ext] = fileparts(varargin{a});
            if ~isempty(p)
                options.name = [p filesep options.name];
            end
            switch lower(ext)
                case {'.tif', '.tiff'}
                    options.tif = true;
                case {'.jpg', '.jpeg'}
                    options.jpg = true;
                case '.png'
                    options.png = true;
                case '.bmp'
                    options.bmp = true;
                case '.eps'
                    options.eps = true;
                case '.pdf'
                    options.pdf = true;
                otherwise
                    options.name = varargin{a};
            end
        end
    end
end

% Set default anti-aliasing now we know the renderer
if options.aa_factor == 0
    options.aa_factor = 1 + 2 * (~using_hg2(fig) | (options.renderer == 3));
end

% Convert user dir '~' to full path
if numel(options.name) > 2 && options.name(1) == '~' && (options.name(2) == '/' || options.name(2) == '\')
    options.name = fullfile(char(java.lang.System.getProperty('user.home')), options.name(2:end));
end

% Compute the magnification and resolution
if isempty(options.magnify)
    if isempty(options.resolution)
        options.magnify = 1;
        options.resolution = 864;
    else
        options.magnify = options.resolution ./ get(0, 'ScreenPixelsPerInch');
    end
elseif isempty(options.resolution)
    options.resolution = 864;
end  

% Check we have a figure handle
if isempty(fig)
    error('No figure found');
end

% Set the default format
if ~isvector(options) && ~isbitmap(options)
    options.png = true;
end

% Check whether transparent background is wanted (old way)
if isequal(get(ancestor(fig(1), 'figure'), 'Color'), 'none')
    options.transparent = true;
end

% If requested, set the resolution to the native vertical resolution of the
% first suitable image found
if native && isbitmap(options)
    % Find a suitable image
    list = findobj(fig, 'Type', 'image', 'Tag', 'export_fig_native');
    if isempty(list)
        list = findobj(fig, 'Type', 'image', 'Visible', 'on');
    end
    for hIm = list(:)'
        % Check height is >= 2
        height = size(get(hIm, 'CData'), 1);
        if height < 2
            continue
        end
        % Account for the image filling only part of the axes, or vice
        % versa
        yl = get(hIm, 'YData');
        if isscalar(yl)
            yl = [yl(1)-0.5 yl(1)+height+0.5];
        else
            if ~diff(yl)
                continue
            end
            yl = yl + [-0.5 0.5] * (diff(yl) / (height - 1));
        end
        hAx = get(hIm, 'Parent');
        yl2 = get(hAx, 'YLim');
        % Find the pixel height of the axes
        oldUnits = get(hAx, 'Units');
        set(hAx, 'Units', 'pixels');
        pos = get(hAx, 'Position');
        set(hAx, 'Units', oldUnits);
        if ~pos(4)
            continue
        end
        % Found a suitable image
        % Account for stretch-to-fill being disabled
        pbar = get(hAx, 'PlotBoxAspectRatio');
        pos = min(pos(4), pbar(2)*pos(3)/pbar(1));
        % Set the magnification to give native resolution
        options.magnify = (height * diff(yl2)) / (pos * diff(yl));
        break
    end
end
return

function A = downsize(A, factor)
% Downsample an image
if factor == 1
    % Nothing to do
    return
end
try
    % Faster, but requires image processing toolbox
    A = imresize(A, 1/factor, 'bilinear');
catch
    % No image processing toolbox - resize manually
    % Lowpass filter - use Gaussian as is separable, so faster
    % Compute the 1d Gaussian filter
    filt = (-factor-1:factor+1) / (factor * 0.6);
    filt = exp(-filt .* filt);
    % Normalize the filter
    filt = single(filt / sum(filt));
    % Filter the image
    padding = floor(numel(filt) / 2);
    for a = 1:size(A, 3)
        A(:,:,a) = conv2(filt, filt', single(A([ones(1, padding) 1:end repmat(end, 1, padding)],[ones(1, padding) 1:end repmat(end, 1, padding)],a)), 'valid');
    end
    % Subsample
    A = A(1+floor(mod(end-1, factor)/2):factor:end,1+floor(mod(end-1, factor)/2):factor:end,:);
end
return

function A = rgb2grey(A)
A = cast(reshape(reshape(single(A), [], 3) * single([0.299; 0.587; 0.114]), size(A, 1), size(A, 2)), class(A));
return

function A = check_greyscale(A)
% Check if the image is greyscale
if size(A, 3) == 3 && ...
        all(reshape(A(:,:,1) == A(:,:,2), [], 1)) && ...
        all(reshape(A(:,:,2) == A(:,:,3), [], 1))
    A = A(:,:,1); % Save only one channel for 8-bit output
end
return

function [A, v] = crop_background(A, bcol)
% Map the foreground pixels
[h, w, c] = size(A);
if isscalar(bcol) && c > 1
    bcol = bcol(ones(1, c));
end
bail = false;
for l = 1:w
    for a = 1:c
        if ~all(A(:,l,a) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
bail = false;
for r = w:-1:l
    for a = 1:c
        if ~all(A(:,r,a) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
bail = false;
for t = 1:h
    for a = 1:c
        if ~all(A(t,:,a) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
bail = false;
for b = h:-1:t
    for a = 1:c
        if ~all(A(b,:,a) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
% Crop the background, leaving one boundary pixel to avoid bleeding on
% resize
v = [max(t-1, 1) min(b+1, h) max(l-1, 1) min(r+1, w)];
A = A(v(1):v(2),v(3):v(4),:);
return

function eps_remove_background(fname, count)
% Remove the background of an eps file
% Open the file
fh = fopen(fname, 'r+');
if fh == -1
    error('Not able to open file %s.', fname);
end
% Read the file line by line
while count
    % Get the next line
    l = fgets(fh);
    if isequal(l, -1)
        break; % Quit, no rectangle found
    end
    % Check if the line contains the background rectangle
    if isequal(regexp(l, ' *0 +0 +\d+ +\d+ +r[fe] *[\n\r]+', 'start'), 1)
        % Set the line to whitespace and quit
        l(1:regexp(l, '[\n\r]', 'start', 'once')-1) = ' ';
        fseek(fh, -numel(l), 0);
        fprintf(fh, l);
        % Reduce the count
        count = count - 1;
    end
end
% Close the file
fclose(fh);
return

function b = isvector(options)
b = options.pdf || options.eps;
return

function b = isbitmap(options)
b = options.png || options.tif || options.jpg || options.bmp || options.im || options.alpha;
return

% Helper function
function A = make_cell(A)
if ~iscell(A)
    A = {A};
end
return

function add_bookmark(fname, bookmark_text)
% Adds a bookmark to the temporary EPS file after %%EndPageSetup
% Read in the file
fh = fopen(fname, 'r');
if fh == -1
    error('File %s not found.', fname);
end
try
    fstrm = fread(fh, '*char')';
catch ex
    fclose(fh);
    rethrow(ex);
end
fclose(fh);

% Include standard pdfmark prolog to maximize compatibility
fstrm = strrep(fstrm, '%%BeginProlog', sprintf('%%%%BeginProlog\n/pdfmark where {pop} {userdict /pdfmark /cleartomark load put} ifelse'));
% Add page bookmark
fstrm = strrep(fstrm, '%%EndPageSetup', sprintf('%%%%EndPageSetup\n[ /Title (%s) /OUT pdfmark',bookmark_text));

% Write out the updated file
fh = fopen(fname, 'w');
if fh == -1
    error('Unable to open %s for writing.', fname);
end
try
    fwrite(fh, fstrm, 'char*1');
catch ex
    fclose(fh);
    rethrow(ex);
end
fclose(fh);
return