# diffTest
## scalable unit testing:
when project is getting longer and test code is getting stacked, test code is getting longer and longer.basically it is not really scalable. how can we solve this issue?

If we use code coverage and diff together we can make it work
- collect code coverage of each individual test
- we need to `Mark` the code coverage and code as one set
- we need to diff changes and compare with `Mark`ed coverage
- there is a change in `covered` code for specific test meaning we have to run that test
- there is no change in `covered` code for specific test meaning we don't need to run the test


## How to use
difftest mark path-to-xcodeProject : (assume git repo is in same dir) 
  commit the test marking
difftest test path-to-xcodeProject : 
  diff with the marking, and test only the test that is broken

(for now)
1. make any change and commit in DiffTestSample project

2. Mark
open edit scheme 
diffTest/ run/ argument tab
add below 2 arguments
- "test"
- "--root /Users/albertqpark/code/DiffTest/DiffTestSample"
run diffTest target will mark 



3. Diff Test
open edit scheme 
diffTest/ run/ argument tab
add below 2 arguments
- "mark"
- "--root /Users/albertqpark/code/DiffTest/DiffTestSample"
run diffTest target will mark 

DiffTestSample will do the "diff testing" against latest marking

### Limitation
some code change will not break the previous test coverages but alter them.
  - overriding function will alter the coverage without breaking previous code  

## Mile Stone TODO
### TODO until v1.0.0
  - easy way to install : may be homebrew?
  - check not only Sample Code but in real situations
  - apply test-without-build
  - more optimization - reduce temp file handover; change it to more direct object hand overs

### TODO until v2.0.0
  - marking during diff test? : mostly possible, but more to investigate

### back log TODO
  - DiffTestSample/.gitattributes to be binary then current approach
  - make version printing system, make integral versioning
  - not do the command line testing but make and insert test-suite into xcode so that xcode interaction possible, able to see code coverage in xcode and coverage reports in xcode

## STEP to make it work
- `Mark`
  1. with clean commited code, (build for testing)
  2. run the full-unit test (test without build)
  3. from full-unit test collect all existing test functions
  4. for each individual test functions, run test with code coverage (test without build)
  5. convert and combine `(all individual test > code coverage)` into `(code line > covered by test functions)`
    - be aware perTestCoverageMap.json is generated based on slather reports line coverage count array, line is line Index, not line Number
      line Index starts from 0, different from regular line Number that will start from 1 
  6. commit `(code line > covered by test function)` with  `diffMark` tag

- `diffTest`
  1. when new code change happens collect  with `diffMark` tag
  2. check `(code line > covered by test function)` 
    if some line that is covered by test functions, run those tests only


## Usage
mostly thinking running this as below cases :
- `Mark`ing happens in server-side CI like Jenkins machine and `diffTest` will do in engineers local machine
- `Mark`ing happens in server-side CI like Jenkins machine per long-time-period and  `diffTest` will be running on each PR or short-time-period
- not only UnitTesting but also UITesting can do the same thing, and it will help much more while it is more time consuming tasks there.








## Dev notes. 
### below are just dev notes what to do

go build -o diffTest ./cmd/diffTest

## step in command line

``` bash
rm -rf ./temp
```

1. do the total test
``` bash
xcodebuild \
-project /Volumes/data/code/DiffTest/DiffTestSample/DiffTestSample.xcodeproj \
-scheme DiffTestSample \
-destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" \
-resultBundlePath ./temp/result/total-test-results.xcresult \
-derivedDataPath ./temp/build \
 clean build test
```

2. list individual tests from ./testresults/total-test-results.xcresult
``` bash
xcrun  xcresulttool get test-results tests \
--path ./temp/result/total-test-results.xcresult \
> ./temp/result/total-test-results.json
```

``` bash
./diffTest extract   
```

3. run each individual tests collecting codecoverage
``` bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
-project /Volumes/data/code/DiffTest/DiffTestSample/DiffTestSample.xcodeproj \
-scheme DiffTestSample \
-destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" \
-derivedDataPath ./temp/build \
-resultBundlePath ./temp/result/DiffTestSampleTests_DiffTestSampleTests_swiftToggle1.xcresult \
-enableCodeCoverage YES \
-only-testing:"DiffTestSampleTests/DiffTestSampleTests/swiftToggle1()" \
 test 
```

``` bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
-project /Volumes/data/code/DiffTest/DiffTestSample/DiffTestSample.xcodeproj \
-scheme DiffTestSample \
-destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" \
-derivedDataPath ./temp/build \
-resultBundlePath ./temp/result/DiffTestSampleTests_DiffSampleXCTests_testXCToggle2.xcresult \
-enableCodeCoverage YES \
-only-testing:"DiffTestSampleTests/DiffSampleXCTests/testXCToggle2" \
 test 
```




4. combine individual tests codecoverage into one file
``` bash
xcrun xccov view --report \
--json \
./temp/result/DiffTestSampleTests_DiffTestSampleTests_swiftToggle1.xcresult \
> ./temp/result/DiffTestSampleTests_DiffTestSampleTests_swiftToggle1.json
``` 
``` bash
xcrun xccov view \
--file ./DiffTestSample/DiffTestSample/ContentViewModel.swift \
--json \
./temp/result/DiffTestSampleTests_DiffTestSampleTests_swiftToggle1.xcresult
```

``` bash
xcrun xccov view --report \
--json \
./temp/result/DiffTestSampleTests_DiffTestSampleTests_swiftToggle1.xcresult \
> ./temp/result/DiffTestSampleTests_DiffSampleXCTests_testXCToggle2.json
``` 
``` bash
xcrun xccov view \
--file ./DiffTestSample/DiffTestSample/ContentViewModel.swift \
--json \
./temp/result/DiffTestSampleTests_DiffSampleXCTests_testXCToggle2.xcresult
```

``` bash
xcrun xcresulttool get \
  --legacy \
  --path ./temp/result/DiffTestSampleTests_DiffSampleXCTests_testXCToggle2.xcresult \
  --id 0~rAYtr2dWH3GXWmZJceggAUmOjYq_yzYOBidj40vKgg619dydNt1V9CNhj7g6RyoQVCsli-8X6fo7TKN30s475Q== \
  --format json > DiffTestSampleTests_DiffSampleXCTests_testXCToggle2_coverage.json
```

``` bash
slather coverage \
  --workspace DiffTestSample.xcodeproj \
  --scheme DiffTestSample \
  --build-directory ./temp/result/DiffTestSampleUITests/DiffTestSampleUITestsLaunchTests/testLaunch/build \
  --output-directory ./temp/result/DiffTestSampleUITests/DiffTestSampleUITestsLaunchTests/testLaunch \
  --json \
  ./DiffTestSample.xcodeproj
'''

5. make a git commit 
- 태깅준비
``` bash
cd .
git fetch
COMMIT_HASH=$(git rev-parse HEAD)
git rev-parse -q --verify "test_marker/$COMMIT_HASH"
```

- 태깅 파일 저장
``` bash
git fetch
COMMIT_HASH=$(git rev-parse HEAD)
echo $COMMIT_HASH > \(Const.markerPath)/marked_hash.txt
```

- 모든 다른 파일과 함께 태깅 커밋
``` bash
git add \(Const.markerPath)/
git commit --message "DiffTest Marker Against $COMMIT_HASH | \(message) \n "
```

- 태깅하기
``` bash
git tag "test_marker/$COMMIT_HASH" -m "per test coverage marked"
```


6. diffSuite
- get marked_hash.txt > markedHash
``` bash 
cat ./.test_marker/marked_hash.txt
```

- diff with markedHash
``` bash
mkdir temp
git diff fee15d0f5bf6bf89747be4bb363ba765441f232b > temp/diff.txt
```

- collect changed line numbers in diff
``` bash
```

- get markerCoverageMapFile > perTestCoverageMap
- collect test in changed line > testNeeded
- get test_list > testList
- filter testNeeded from testList > testNotNeeded
-  xcode build test with -skip-testing:testNotNeeded
- can we create and insert TestPlan with this?
  * so that it can run in Xcode UI > display result xcode more easy