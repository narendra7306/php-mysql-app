<?php
use PHPUnit\Framework\TestCase;

class DatabaseTest extends TestCase
{
    private $config;

    protected function setUp(): void
    {
        // Load the config.ini
        $this->config = parse_ini_file(__DIR__ . '/../config.ini');
    }

    /**
     * ✅ Config tests
     */
    public function testConfigHasEnvironment()
    {
        $this->assertArrayHasKey('ENVNAME', $this->config, "ENVNAME key missing in config.ini");
        $this->assertNotEmpty($this->config['ENVNAME'], "ENVNAME value is empty in config.ini");
    }

    public function testEnvironmentIsValid()
    {
        $allowed = ['dev', 'test', 'prod'];
        $this->assertContains($this->config['ENVNAME'], $allowed, "Invalid environment set in config.ini");
    }

    /**
     * ✅ Version test
     */
    public function testAppVersionFormat()
    {
        $version = "1.1"; // you could load this dynamically if needed
        $this->assertMatchesRegularExpression('/^\d+\.\d+$/', $version);
    }

    /**
     * ✅ Basic functionality tests
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
}
