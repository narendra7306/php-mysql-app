<?php

use PHPUnit\Framework\TestCase;

class DatabaseTest extends TestCase
{
    private $config;

    protected function setUp(): void
    {
        $this->config = parse_ini_file(__DIR__ . '/../config.ini');
    }

    /**
     * Config Tests
     */
    public function testConfigHasEnvironment()
    {
        $this->assertArrayHasKey('ENVNAME', $this->config);
        $this->assertNotEmpty($this->config['ENVNAME']);
    }

    public function testEnvironmentIsValid()
    {
        $allowed = ['dev', 'test', 'prod'];
        $this->assertContains($this->config['ENVNAME'], $allowed);
    }

    /**
     * Version Test
     */
    public function testAppVersionFormat()
    {
        $version = "1.1";
        $this->assertMatchesRegularExpression('/^\d+\.\d+$/', $version);
    }

    /**
     * Basic PHP Tests
     */
    public function testArrayPush()
    {
        $arr = [];
        array_push($arr, "foo");

        $this->assertCount(1, $arr);
        $this->assertEquals("foo", $arr[0]);
    }

    public function testStringContains()
    {
        $this->assertStringContainsString("Demo", "DevOps Demo Application");
    }

    /**
     * Application Tests
     */

    public function testIndexFileExists()
    {
        $this->assertFileExists(__DIR__ . '/../devops-demo-1.1/index.php');
    }

    public function testIndexFileIsReadable()
    {
        $this->assertIsReadable(__DIR__ . '/../devops-demo-1.1/index.php');
    }

    public function testIndexLoadsWithoutFatalError()
    {
        $indexFile = __DIR__ . '/../devops-demo-1.1/index.php';

        ob_start();

        try {
            include $indexFile;
        } catch (\Throwable $e) {
            ob_end_clean();
            $this->fail("index.php threw an exception: " . $e->getMessage());
        }

        $output = ob_get_clean();

        $this->assertIsString($output);
    }
}

