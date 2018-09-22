clear all;
%% HMM UD
mea_size=433;
mea_size_bm=465; %bigger mea size , from luminance calibrated region
meaCenter_x=631; 
meaCenter_y=580; 

leftx_bd=meaCenter_x-(mea_size_bm-1)/2; %the first x position of the bigger mea region(luminance calibrated region) on LED screen
lefty_bd=meaCenter_y-(mea_size_bm-1)/2;
bar_le=(mea_size-1)/2; %half of bar length / pixel number on LCD /total length = mea_size = 1919 um
bar_wid=11; %half of bar width / total length = 11*2+1=23 pixels = 65 um
%U-D
upy_bar=meaCenter_y-(mea_size-1)/2; %Left boundary of bar
downy_bar=meaCenter_y+(mea_size-1)/2; %Right boundary of bar

G_list=[ 2.5 3 4.3 4.5 5.3 6.3 6.5 7.5 9 12 20];  %list of Gamma value
countt=1;
load('calibrate_pt.mat')%Load dotPositionMatrix
load('screen_brightness.mat')%Load screen_brightness
cd('0421 new video Br25/rn_workspace');  
all_file = dir('*.mat');

fps =60;  %freq of the screen flipping 
T=7*60; %second
dt=1/fps;
T=dt:dt:T;

screen_brightness=screen_brightness./255; %make it to 0-1 range for double (due to imwrite format)
screen_brightness(screen_brightness>1)=1;


for Gvalue=G_list
    cd('/Users/nghdavid/Desktop/make_movie/0421 new video Br25/rn_workspace');
    G_HMM =Gvalue; % damping / only G will influence correlation time
    D_HMM = 2700000; %dynamical range
    omega =G_HMM/2.12;   % omega = G/(2w)=1.06; follow Bielak's overdamped dynamics/ 2015PNAS
    %for randon number files ( I specifically choose some certain random seed series

    file = all_file(countt).name ;
    [pathstr, name, ext] = fileparts(file);
    directory = [pathstr,'\'];
    filename = [name,ext];
    load([filename]);
    name=[name];
    name
    Gvalue
    countt=countt+1;


    Yarray = zeros(1,length(T));
    Yarray(1,1)=0; % since the mean value of damped eq is zero
    Vy = zeros(1,length(T));
    for t = 1:length(T)-1
            Yarray(t+1) = Yarray(t) + Vy(t)*dt;  
            Vy(t+1) = (1-G_HMM*dt)*Vy(t) - omega^2*Yarray(t)*dt + sqrt(dt*D_HMM)*rntest(t); % rntest(t): gaussian noise with zero mean and unit variance
    end
    %Normalize to proper moving range
    nry=(downy_bar-upy_bar)/(max(Yarray)-min(Yarray));
    Yarray2=Yarray*nry;
    mdist=abs(min(Yarray2)-upy_bar);
        if min(Yarray2)>upy_bar
         mdist=-mdist;
        end
    Yarray3=Yarray2+mdist;
    newYarray=round(Yarray3); 
    X = meaCenter_x;

    
    cd ('/Users/nghdavid/Desktop/make_movie/HMM_0819_video_Br_50')
    %video frame file
    name=['0819 HMM UD G',num2str(G_HMM) ,' 7min Br50 Q100'];
    name


    %video setting
    Time=T; %sec
    video_fps=fps;
    writerObj = VideoWriter([name,'.avi']);  %change video name here!
    writerObj.FrameRate = video_fps;
    writerObj.Quality = 100;
    open(writerObj);
    %start part: dark adaptation
    for mm=1:60
        img=zeros(1024,1280);   
        writeVideo(writerObj,img);
    end


    for kk =1:length(T)
        a=zeros(1024,1280);%full screen pixel matrix %it's the LED screen size

        %HMM UD bar trajectory
        Y=newYarray(kk);

        barX=X-round(leftx_bd);
        barY=round(Y)-round(lefty_bd);
        for x = barX-bar_le: barX+bar_le
            for y = barY-bar_wid:barY+bar_wid
               cal_x = dotPositionMatrix{y,x}(1);
               cal_y = dotPositionMatrix{y,x}(2);
               cal_lum = screen_brightness(y,x);
               a(cal_y,cal_x) = cal_lum;
            end
        end
        
        %square_flicker
        if mod(kk,3)==1 %odd number
        a(500-35:500+35,1230:1280)=1; % white square
        elseif mod(kk,3)==2
        a(500-35:500+35,1230:1280)=0.2; %gray 
        else
        a(500-35:500+35,1230:1280)=0; % dark
        end
        
        writeVideo(writerObj,a);
    end

    %end part video
    for mm=1:10
        img=zeros(1024,1280);
        img(500-35:500+35,1230:1280)=0.2; %gray
        writeVideo(writerObj,img);
    end
    close(writerObj);
    cd('/Users/nghdavid/Desktop/make_movie/HMM_0819_video_Br_50_workspace')
    %save parameters needed 
    save(['0819 HMM UD G',num2str(G_HMM) ,' 7min Br50 Q100','.mat'],'newYarray')
    
end
cd('/Users/nghdavid/Desktop/make_movie')
