# diffTest
## scalable unit testing:
when project is getting longer and test code is getting stacked, test code is getting longer and longer.basically it is not really scalable. how can we solve this issue?

If we use code coverage and diff together we can make it work
- collect code coverage of each individual test
- we need to `Mark` the code coverage and code as one set
- we need to diff changes and compare with `Mark`ed coverage
- there is a change in `covered` code for specific test meaning we have to run that test
- there is no change in `covered` code for specific test meaning we don't need to run the test

## STEP to make it work
- `Mark`
  1. with clean commited code, (build for testing)
  2. run the full-unit test (test without build)
  3. from full-unit test collect all existing test functions
  4. for each individual test functions, run test with code coverage (test without build)
  5. convert and combine `(all individual test > code coverage)` into `(code line > covered by test functions)`
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
- diff with markedHash
- collect changed line numbers in diff
- get markerCoverageMapFile > perTestCoverageMap
- collect test in changed line > testNeeded
- get test_list > testList
- filter testNeeded from testList > testNotNeeded
-  xcode build test with -skip-testing:testNotNeeded
- can we create and insert TestPlan with this?
  * so that it can run in Xcode UI > display result xcode more easy