%% Read in video to convert
vid_object = VideoReader("./Data/The.Godfather.1972.1080p.BrRip.x264.BOKUTOX.YIFY.mp4");
%% Initialize RNG with seed as current system time
seed = round(clock()*[0 0 0 0 0 1].'*10000);
rng(seed);
%% Make output folders
mkdir './training_data/'
mkdir './ground_truth/'
%% Convert frames
vid_object.CurrentTime = 100;

frame_count = 2377;
while vid_object.hasFrame
frame = readFrame(vid_object);

% Crop image to 4:3 aspect ratio and 1920x1440
dimensions = size(frame)*[1 0 0; 0 1 0].';
cropped = imresize(frame(1:(dimensions(1)-mod(dimensions(1),3)),1:((dimensions(1)-mod(dimensions(1),3))/3*4),:),[1440 1920]);
converted = convert(cropped);

imwrite(cropped, ".\ground_truth\" + frame_count + ".jpg");
imwrite(converted, ".\training_data\" + frame_count + ".jpg");
frame_count = frame_count + 1;
end

%%
function I = convert(frame)
    Kr = 0.299;
    Kg = 0.587;
    Kb = 0.114;

    color = [Kr Kg Kb; -0.5*Kr/(1-Kb) -0.5*Kg/(1-Kb) 0.5; 0.5 -0.5*Kg/(1-Kr) -0.5*Kb/(1-Kr)];
    color_inv = round(inv(color), 5);

    % Resize to 480x640
    frame = imresize(frame, [480 640]);

    % Normalize to [0,1]
    normalized = single(frame)/255;

    % Convert to YUV
    Y = 0.299*normalized(:,:,1) + 0.587*normalized(:,:,2) + 0.114*normalized(:,:,3);
    U = 0.492*(normalized(:,:,3) - Y);
    V = 0.877*(normalized(:,:,1) - Y);

    % Process each line separately
    for line = 1:480
        Y(line,:) = imresize(circshift(imresize(Y(line,:), [1 6400]),round(rand()*15)), [1 640]);
    end

    % Chroma subsampling
    U = imresize(lowpass(imresize(U, [480 80]).',0.3).', [480 640]);
    V = imresize(lowpass(imresize(V, [480 80]).',0.3).', [480 640]);
    Y = imresize(lowpass(imresize(Y, [480 320]).',0.7).', [480 640]);

    % Add chrominance noise
    U = U + imresize(lowpass((rand([640 240])-0.5)/8,0.3).', [480 640]);
    V = V + imresize(lowpass((rand([640 240])-0.5)/8,0.3).', [480 640]);

    YUV_filtered = cat(3, cat(3, Y, U), V);
    I = uint8(permute(pagemtimes(color_inv, permute(double(YUV_filtered), [3 2 1])), [3 2 1])*255);
end