//
//  OpenCVCalculations.mm
//  OpenCVClient
//
//  Created by Ron Slossberg on 4/24/12.
//  Copyright (c) 2012 Aptogo Limited. All rights reserved.
//

#import "OpenCVCalculations.h"

using namespace std;
using namespace cv;


/*
 Method      : StereoCalib
 Parameters  :cv::Mat img  - chessboard image to process
              cv::Size boardSize - number of corners in chessboard
              cv::vector<cv::vector<cv::Point2f> >(&imagePoints)[2] - this complex data structure holds the points for left and right camera in a vector where each cell holds a set of points for one chessboard image (see opencv examples for reference)
              int numImage - sequential number for this image
              cv::Mat& cornersImg - output image of the chessboard corners image for later display
 
 Returns     : returns true on success
 Description : this function takes the chessboard image and openCV algorithms to find the corners and update the corners data
 */

bool StereoCalib(cv::Mat img , cv::Size boardSize,cv::vector<cv::vector<cv::Point2f> >(&imagePoints)[2],int numImage, cv::Mat& cornersImg)
{
    bool displayCorners = true;
    const int maxScale = 2;
    
    // this code is taken from openCV example code for finding chessboard corners
    // we use several scales of the image to find the corners in the optimal way
            bool found = false;
            vector<Point2f>& corners = imagePoints[0][numImage];
            for( int scale = 1; scale <= maxScale; scale++ )
            {
                Mat timg;
                if ( scale == 1 )
                    timg = img;
                else
                    resize(img, timg, cv::Size(), scale, scale);
                
                found = findChessboardCorners(timg, boardSize, corners, 
                                              CV_CALIB_CB_ADAPTIVE_THRESH | CV_CALIB_CB_NORMALIZE_IMAGE);
                if( found )
                {
                    if( scale > 1 )
                    {
                        Mat cornersMat(corners);
                        cornersMat *= 1./scale;
                    }
                    break;
                }
            }
            if( displayCorners ) // create the image with the corners drawn on it
            {
                
                Mat cimg;
                cvtColor(img, cimg, CV_GRAY2BGR);
                drawChessboardCorners(cimg, boardSize, corners, found);
                
                double sf = 640./MAX(img.rows, img.cols);
                resize(cimg, cornersImg, cv::Size(), sf, sf);
                
            }
            if( !found )
                return false;
    
            // also from opencv example, find subpixel accuracy for the corners. otherwise the corner coordinates aren't accurate enough.
            cornerSubPix(img, corners, cv::Size(11,11), cv::Size(-1,-1), TermCriteria(CV_TERMCRIT_ITER+CV_TERMCRIT_EPS, 30, 0.01));
    return true;

}


/*
 Method      : calibrateCameras
 Parameters  :cv::Size boardSize - size of chessboard (number of corners in each direction)
              cv::vector<cv::vector<cv::Point2f> >(& imagePoints)[2] - data structure that holds all found corners from left and right cameras (see openCV examples)
              cv::vector<cv::vector<cv::Point3f> >& objectPoints    - data structure for the object data used for the calibration methods (see openCV examples)
              int numImage   - number of calibration images taken
              cv::Size imageSize     - size of each image
              const float squareHeight  -  height of chessboard square
              float squareWidth     -   widht of chessboard square
 
 Returns     : double - rms error (root meen square of error)
 Description : this function takes as input the set of coordinates we identified earlier and preforms the calibraton process.
               all the parameters from the calibration are saved to memory for later use.
 */
double calibrateCameras( cv::Size boardSize,cv::vector<cv::vector<cv::Point2f> >(& imagePoints)[2], cv::vector<cv::vector<cv::Point3f> >& objectPoints, int numImage , cv::Size imageSize , const float squareHeight, float squareWidth)
{
    
    imagePoints[0].resize(numImage);
    imagePoints[1].resize(numImage);
    objectPoints.resize(numImage);
    // create object corners data artificially
    
    int i , j , k;

    for( i = 0; i < numImage; i++ )
    {
        for( j = 0; j < boardSize.height; j++ )
            for( k = 0; k < boardSize.width; k++ )
                objectPoints[i].push_back(Point3f(j * squareHeight, k * squareWidth, 0));
    }

    // create all matrices for calibration
    Mat cameraMatrix[2], distCoeffs[2];
    cameraMatrix[0] = Mat::eye(3, 3, CV_64F);
    cameraMatrix[1] = Mat::eye(3, 3, CV_64F);
    distCoeffs[0] = Mat::zeros(1, 5, CV_64F);
    distCoeffs[1] = Mat::zeros(1, 5, CV_64F);
    Mat R, T, E, F;
    double rms;
    
    // preform intrinsic camera calibration for both cameras initially to make calibration process more accurate
    
        vector<Mat> rvecs;
        vector<Mat> tvecs;
        calibrateCamera(objectPoints, imagePoints[0], imageSize, cameraMatrix[0], distCoeffs[0], rvecs, tvecs, CV_CALIB_SAME_FOCAL_LENGTH + CV_CALIB_ZERO_TANGENT_DIST+CV_CALIB_FIX_K3);
        calibrateCamera(objectPoints, imagePoints[1], imageSize, cameraMatrix[1], distCoeffs[1], rvecs, tvecs, CV_CALIB_SAME_FOCAL_LENGTH + CV_CALIB_ZERO_TANGENT_DIST+CV_CALIB_FIX_K3);
    
    // use the calculated intrinsic parameters and calculate the remaining extrinsic parameters
    
    rms = stereoCalibrate(objectPoints, imagePoints[0], imagePoints[1],
                          cameraMatrix[0], distCoeffs[0],
                          cameraMatrix[1], distCoeffs[1],
                          imageSize, R, T, E, F,
                          TermCriteria(CV_TERMCRIT_ITER+CV_TERMCRIT_EPS, 100, 1e-5), CV_CALIB_FIX_INTRINSIC+CV_CALIB_SAME_FOCAL_LENGTH);
    
    // store the computed values of the calibration process using our own data storing functions
    [manageCVMat storeCVMat:R withKey:@"Rarray"];
    [manageCVMat storeCVMat:T withKey:@"Tarray"];
    [manageCVMat storeCVMat:F withKey:@"Farray"];
    [manageCVMat storeCVMat:E withKey:@"Earray"];
    [manageCVMat storeCVMat:cameraMatrix[0] withKey:@"K0array"];
    [manageCVMat storeCVMat:cameraMatrix[1] withKey:@"K1array"];
    [manageCVMat storeCVMat:distCoeffs[0] withKey:@"D0array"];
    [manageCVMat storeCVMat:distCoeffs[1] withKey:@"D1array"];
    
    // return the calibration error for display
    return rms;
    
}

/*
 Method      : createMap
 Parameters  :const cv::Size imgSize  - size of image to remap
              cv::Mat &Q  - reprojection matrix output
              cv::Mat &map11  -
              cv::Mat &map12  -
              cv::Mat &map21  -
              cv::Mat &map22  - remap matrices for later use
              cv::Rect &roi1  -
              cv::Rect &roi2  - region of interest rectangles for later use
 Returns     : void
 Description : this function takes creates all the matrices and data neede to create remap of a photo according to the calibration parameters and stores them in the output matrices for later use
 */
void createMap(const cv::Size imgSize, cv::Mat &Q , cv::Mat &map11 , cv::Mat &map12 , cv::Mat &map21 , cv::Mat &map22 ,cv::Rect &roi1 , cv::Rect &roi2 )
{
    // init all matrices;
    Mat cameraMatrix[2], distCoeffs[2];
    cameraMatrix[0] = Mat::zeros(3, 3, CV_64F);
    cameraMatrix[1] = Mat::zeros(3, 3, CV_64F);
    distCoeffs[0] = Mat::zeros(1, 5, CV_64F);
    distCoeffs[1] = Mat::zeros(1, 5, CV_64F);
    Mat R, T;
    R = Mat::zeros(3, 3, CV_64F);
    T = Mat::zeros(1, 3, CV_64F);
    
    // load calibration data into matrices using our data management functions
    cameraMatrix[0] = [manageCVMat loadCVMat:cv::Size(3,3) WithKey:@"K0array"];
    cameraMatrix[1] = [manageCVMat loadCVMat:cv::Size(3,3) WithKey:@"K1array"];
    distCoeffs[0] = [manageCVMat loadCVMat:cv::Size(1,5) WithKey:@"D0array"];
    distCoeffs[1] = [manageCVMat loadCVMat:cv::Size(1,5) WithKey:@"D1array"];
    R = [manageCVMat loadCVMat:cv::Size(3,3) WithKey:@"Rarray"];
    T = [manageCVMat loadCVMat:cv::Size(1,3) WithKey:@"Tarray"];
    
    cv::Size img_size = imgSize;
    
    Mat R1, P1, R2, P2;
    
    // preform stereo rectify to get back R1 P1 R2 P2 for remap
    cv::stereoRectify( cameraMatrix[0], distCoeffs[0], cameraMatrix[1], distCoeffs[1], img_size, R, T, R1, R2, P1, P2, Q, CALIB_ZERO_DISPARITY, -1, img_size, &roi1, &roi2 );
    
    // use all data to create rectification and undistortion maps
    cv::initUndistortRectifyMap(cameraMatrix[0], distCoeffs[0], R1, P1, img_size, CV_16SC2, map11, map12);
    cv::initUndistortRectifyMap(cameraMatrix[1], distCoeffs[1], R2, P2, img_size, CV_16SC2, map21, map22);
    
}

/*
 Method      : reconstruct
 Parameters  :cv::Size imageSize  - image size
              cv::Mat* img1  - first image
              cv::Mat* img2  - second image
              cv::Mat* outImg - this map will store the 3d point cloud data
              cv::Mat &map11
              cv::Mat &map12 
              cv::Mat &map21 
              cv::Mat &map22 - rectification map matrices used to recify and undistort ( calculated once when view is loaded )
              cv::Rect &roi1 
              cv::Rect &roi2 - region of interest for rectify function
              cv::Mat &Q - reprojection matrix
              int algType   - algorighem type used for stereo matching ( BM or SGBM )
 Returns     : void
 Description : this function takes two images and the rectification matrices and creates the disparity map and the reprojected 3d point cloud using one of two algorithems offered by openCV
 */
void reconstruct(cv::Size imageSize , cv::Mat* img1 , cv::Mat* img2 ,cv::Mat* outImg,cv::Mat &map11 , cv::Mat &map12 , cv::Mat &map21 , cv::Mat &map22 ,cv::Rect &roi1 , cv::Rect &roi2 , cv::Mat &Q, int algType)
{
    enum { STEREO_BM=0, STEREO_SGBM=1 };
int SADWindowSize = 0, numberOfDisparities = 0;
    
    
    // setup openCV objects for stereo matching algorithems
    StereoSGBM sgbm;
    StereoBM bm;
    cv::Size img_size = img1->size();
    

    // remap the images using the precalculated maps in preparation for matching algorithem
    cv::Mat img1r, img2r;
    cv::remap(*img1, img1r, map11, map12, INTER_LINEAR);
    cv::remap(*img2, img2r, map21, map22, INTER_LINEAR);
    
    // this code creates a combined image from left and right images with lines through them to see if the rectification process is successfull.
    // one may choose to view this image later for debug purposes
    // right now this image is not used in any way
    Mat canvas;
    double sf;
    int w, h;
        sf = 600./MAX(imageSize.width, imageSize.height);
        w = cvRound(imageSize.width*sf);
        h = cvRound(imageSize.height*sf);
        canvas.create(h, w*2, CV_8UC3);
    

        Mat rimg, cimg;
        cvtColor(img1r, cimg, CV_GRAY2BGR);
        Mat canvasPart =  canvas(cvRect(0, 0, w, h));
        resize(cimg, canvasPart, canvasPart.size(), 0, 0, CV_INTER_AREA);
        cvtColor(img2r, cimg, CV_GRAY2BGR);
        canvasPart =  canvas(cvRect(w, 0, w, h));
        resize(cimg, canvasPart, canvasPart.size(), 0, 0, CV_INTER_AREA);

    int j;
        for( j = 0; j < canvas.rows; j += 16 )
            line(canvas, cvPoint(0, j), cvPoint(canvas.cols, j), Scalar(0, 255, 0), 1, 8);


    
    *img1 = img1r;
    *img2 = img2r;
    
    // setup all parameters for bm and sgbm algorithems
    // we took the numbers from theopenCV example code
    
    numberOfDisparities = numberOfDisparities > 0 ? numberOfDisparities : ((img_size.width/8) + 15) & -16;
    
    bm.state->roi1 = roi1;
    bm.state->roi2 = roi2;
    bm.state->preFilterCap = 31;
    bm.state->SADWindowSize = SADWindowSize > 0 ? SADWindowSize : 9;
    bm.state->minDisparity = 0;
    bm.state->numberOfDisparities = numberOfDisparities;
    bm.state->textureThreshold = 10;
    bm.state->uniquenessRatio = 10;
    bm.state->speckleWindowSize = 100;
    bm.state->speckleRange = 32;
    bm.state->disp12MaxDiff = 1;
    
    
    
    sgbm.preFilterCap = 63;
    sgbm.SADWindowSize = 9;
    
    int cn = img1->channels();

    sgbm.P1 = 8*cn*sgbm.SADWindowSize*sgbm.SADWindowSize;
    sgbm.P2 = 32*cn*sgbm.SADWindowSize*sgbm.SADWindowSize;
    sgbm.minDisparity = 0;
    sgbm.numberOfDisparities = numberOfDisparities;
    sgbm.uniquenessRatio = 10;
    sgbm.speckleWindowSize = 100;
    sgbm.speckleRange = 32;
    sgbm.disp12MaxDiff = 1;
    sgbm.fullDP = 0;
    
    
    Mat disp, disp8;
    Mat xyz = Mat(img1->rows, img1->cols, CV_32FC3);
    
    // apply the correct algorithm and use the disp mat for result
    if (algType == 0) {
        sgbm(*img1,*img2,disp);
    }
    else {
        bm(*img1, *img2, disp);
    }
    
    // this code reprojects the disparity map into point cloud using the Q reprojection matrix (I had some problems with the opencv reproject function and this way seemed easyer)
    double Q03, Q13, Q23, Q32, Q33;
    Q03 = Q.at<double>(0,3);
    Q13 = Q.at<double>(1,3);
    Q23 = Q.at<double>(2,3);
    Q32 = Q.at<double>(3,2);
    Q33 = Q.at<double>(3,3);
    disp.convertTo(disp8, CV_8U, 255/(numberOfDisparities*16.));

    
    double px, py, pz;
    for (int i = 0; i < img1->rows; i++)
    {
        uchar* disp_ptr = disp8.ptr<uchar>(i);


        for (int j = 0; j < img1->cols; j++)
        {
            //Get 3D coordinates
            uchar d = disp_ptr[j];

            double pw = -1.0 * static_cast<double>(d) * Q32 + Q33;
            px = static_cast<double>(j) + Q03;
            py = static_cast<double>(i) + Q13;
            pz = Q23;
            
            if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"side"] hasPrefix:@"Left"] ){
                px = px/pw;
                py = py/pw;
                pz = pz/pw;
            }
            else{
                px = -px/pw;
                py = -py/pw;
                pz = -pz/pw;
            }
        
            xyz.at<Vec3f>(i,j)[0] = px;
            xyz.at<Vec3f>(i,j)[1] = py;
            xyz.at<Vec3f>(i,j)[2] = pz;
        }
    }


    //reprojectImageTo3D(disp, xyz, Q, true);  //  this does not work well (don't know why)
    
    // put calculated images into outside pointers for later use
    *outImg = xyz;
    *img1 = canvas;
    *img2 = disp8;
}

