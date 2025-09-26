# Dev notes. 
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